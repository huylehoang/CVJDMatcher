//
//  LegacyGPT2ReasoningService.swift
//  CVJDMatcher
//
//  Created by Le Hoang Huy on 7/7/25.
//

final class LegacyGPT2ReasoningService: ReasoningService {
    private var gpt2: GPT2!

    func loadModel() async throws {
        gpt2 = GPT2(strategy: .topK(20))
    }

    func explain(jd: String, cv: String) async throws -> String {
        let prompt = """
        You are an AI assistant trained to assess job fit between \
        a job description and a candidate CV.
        
        Your task:
        Analyze the following job description and CV.
        Respond using this format only:
        Match: Yes or No  
        Reason: A concise explanation (1–2 sentences) justifying the match decision.
        
        ---
        
        Now Evaluate this pair:
        
        --- JOB DESCRIPTION START ---
        \(jd)
        --- JOB DESCRIPTION END ---
        
        --- CANDIDATE CV START ---
        \(cv)
        --- CANDIDATE CV END ---
        
        Match: <Your Answer>
        Reason: <Your Evaluation>
        """
        let fullOutput = gpt2.generate(text: prompt, nTokens: 80, callback: { output, time in
            let formattedTime = String(format: "%.2fs", time)
            print("📤 [\(formattedTime)] \(output)")
        })
        let trimmed = fullOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed
    }
}
