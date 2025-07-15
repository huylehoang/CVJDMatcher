//
//  VectorDBRAGService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 15/7/25.
//

final class VectorDBRAGService: RAGService {
    private let embeddingService: EmbeddingService
    private let llmService: LLMService
    private let promptService: PromptService
    private let vectorDB: VectorDatabase
    private let chunker: Chunker
    private let topK: Int

    init(
        embeddingService: EmbeddingService = MiniLMEmbeddingService(),
        llmService: LLMService = MediaPipeLLMService.gemma_2b_it_cpu_int8,
        promptService: PromptService = PromptServiceV1(),
        vectorDB: VectorDatabase = MiniLMVectorDatabase(),
        chunker: Chunker = SlidingWindowChunker(),
        topK: Int = 3
    ) {
        self.embeddingService = embeddingService
        self.llmService = llmService
        self.promptService = promptService
        self.vectorDB = vectorDB
        self.chunker = chunker
        self.topK = topK
    }

    func setup() async throws {
        try await embeddingService.loadModel()
        try await llmService.loadModel()
        try vectorDB.setup()
    }

    func indexData(_ data: [String]) throws {
        let vectors = try data.map { cv -> (text: String, embedding: [Float]) in
            let chunks = try chunker.chunk(text: cv)
            let finalEmbedding: [Float]
            if chunks.isEmpty {
                finalEmbedding = try embeddingService.embed(cv)
            } else {
                let chunkEmbeds = try chunks.map { try embeddingService.embed($0.text) }
                finalEmbedding = chunkEmbeds
                    .reduce([Float](repeating: 0, count: chunkEmbeds[0].count)) { acc, vec in
                        zip(acc, vec).map(+)
                    }
                    .map { $0 / Float(chunkEmbeds.count) }
            }
            return (text: cv, embedding: finalEmbedding)
        }
        try vectorDB.clear()
        try vectorDB.index(vectors: vectors)
    }

    func generateReponse(for query: String, onPartial: ((String) -> Void)?) async throws -> String {
        let jdVec = try embeddingService.embed(query)
        let topVectors = try vectorDB.search(queryVector: jdVec, topK: topK)
        if topVectors.isEmpty {
            return emptyResponse
        }
        llmService.onPartialOuput = {
            onPartial?($0.cleanedLLMResponse)
        }
        let prompt = promptService.prompt(
            jd: query,
            cvs: topVectors.cvs,
            topK: topK
        )
        let response = try await llmService.generateResponse(for: prompt)
        return response.cleanedLLMResponse
    }
}

private extension [Vector] {
    var cvs: String {
        enumerated()
            .map { "Candidate \($0 + 1): \($1.cleanedCV)" }
            .joined(separator: "\n\n")
    }
}

private extension Vector {
    var cleanedCV: String {
        text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
