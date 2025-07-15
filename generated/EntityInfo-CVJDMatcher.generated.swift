// Generated using the ObjectBox Swift Generator — https://objectbox.io
// DO NOT EDIT

// swiftlint:disable all
import ObjectBox
import Foundation

// MARK: - Entity metadata

extension MiniLMVector: ObjectBox.Entity {}
extension NLVector: ObjectBox.Entity {}
extension StsbRobertaVector: ObjectBox.Entity {}

extension MiniLMVector: ObjectBox.__EntityRelatable {
    internal typealias EntityType = MiniLMVector

    internal var _id: EntityId<MiniLMVector> {
        return EntityId<MiniLMVector>(self.id.value)
    }
}

extension MiniLMVector: ObjectBox.EntityInspectable {
    internal typealias EntityBindingType = MiniLMVectorBinding

    /// Generated metadata used by ObjectBox to persist the entity.
    internal static let entityInfo = ObjectBox.EntityInfo(name: "MiniLMVector", id: 1)

    internal static let entityBinding = EntityBindingType()

    fileprivate static func buildEntity(modelBuilder: ObjectBox.ModelBuilder) throws {
        let entityBuilder = try modelBuilder.entityBuilder(for: MiniLMVector.self, id: 1, uid: 6773826225877089536)
        try entityBuilder.addProperty(name: "id", type: PropertyType.long, flags: [.id], id: 1, uid: 7295785771196217856)
        try entityBuilder.addProperty(name: "text", type: PropertyType.string, id: 2, uid: 3362162938798080768)
        try entityBuilder.addProperty(name: "embedding", type: PropertyType.floatVector, flags: [.indexed], id: 3, uid: 7169937976749930752, indexId: 1, indexUid: 491946182654952704)
            .hnswParams(dimensions: 384, neighborsPerNode: nil, indexingSearchCount: nil, flags: nil, distanceType: nil, reparationBacklinkProbability: nil, vectorCacheHintSizeKB: nil)

        try entityBuilder.lastProperty(id: 3, uid: 7169937976749930752)
    }
}

extension MiniLMVector {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { MiniLMVector.id == myId }
    internal static var id: Property<MiniLMVector, Id, Id> { return Property<MiniLMVector, Id, Id>(propertyId: 1, isPrimaryKey: true) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { MiniLMVector.text.startsWith("X") }
    internal static var text: Property<MiniLMVector, String, Void> { return Property<MiniLMVector, String, Void>(propertyId: 2, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { MiniLMVector.embedding.isNotNil() }
    internal static var embedding: Property<MiniLMVector, HnswIndexPropertyType, Void> { return Property<MiniLMVector, HnswIndexPropertyType, Void>(propertyId: 3, isPrimaryKey: false) }

    fileprivate func __setId(identifier: ObjectBox.Id) {
        self.id = Id(identifier)
    }
}

extension ObjectBox.Property where E == MiniLMVector {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .id == myId }

    internal static var id: Property<MiniLMVector, Id, Id> { return Property<MiniLMVector, Id, Id>(propertyId: 1, isPrimaryKey: true) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .text.startsWith("X") }

    internal static var text: Property<MiniLMVector, String, Void> { return Property<MiniLMVector, String, Void>(propertyId: 2, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .embedding.isNotNil() }

    internal static var embedding: Property<MiniLMVector, HnswIndexPropertyType, Void> { return Property<MiniLMVector, HnswIndexPropertyType, Void>(propertyId: 3, isPrimaryKey: false) }

}


/// Generated service type to handle persisting and reading entity data. Exposed through `MiniLMVector.EntityBindingType`.
internal final class MiniLMVectorBinding: ObjectBox.EntityBinding, Sendable {
    internal typealias EntityType = MiniLMVector
    internal typealias IdType = Id

    internal required init() {}

    internal func generatorBindingVersion() -> Int { 1 }

    internal func setEntityIdUnlessStruct(of entity: EntityType, to entityId: ObjectBox.Id) {
        entity.__setId(identifier: entityId)
    }

    internal func entityId(of entity: EntityType) -> ObjectBox.Id {
        return entity.id.value
    }

    internal func collect(fromEntity entity: EntityType, id: ObjectBox.Id,
                                  propertyCollector: ObjectBox.FlatBufferBuilder, store: ObjectBox.Store) throws {
        let propertyOffset_text = propertyCollector.prepare(string: entity.text)
        let propertyOffset_embedding = propertyCollector.prepare(values: entity.embedding)

        propertyCollector.collect(id, at: 2 + 2 * 1)
        propertyCollector.collect(dataOffset: propertyOffset_text, at: 2 + 2 * 2)
        propertyCollector.collect(dataOffset: propertyOffset_embedding, at: 2 + 2 * 3)
    }

    internal func createEntity(entityReader: ObjectBox.FlatBufferReader, store: ObjectBox.Store) -> EntityType {
        let entity = MiniLMVector()

        entity.id = entityReader.read(at: 2 + 2 * 1)
        entity.text = entityReader.read(at: 2 + 2 * 2)
        entity.embedding = entityReader.read(at: 2 + 2 * 3)

        return entity
    }
}



extension NLVector: ObjectBox.__EntityRelatable {
    internal typealias EntityType = NLVector

    internal var _id: EntityId<NLVector> {
        return EntityId<NLVector>(self.id.value)
    }
}

extension NLVector: ObjectBox.EntityInspectable {
    internal typealias EntityBindingType = NLVectorBinding

    /// Generated metadata used by ObjectBox to persist the entity.
    internal static let entityInfo = ObjectBox.EntityInfo(name: "NLVector", id: 2)

    internal static let entityBinding = EntityBindingType()

    fileprivate static func buildEntity(modelBuilder: ObjectBox.ModelBuilder) throws {
        let entityBuilder = try modelBuilder.entityBuilder(for: NLVector.self, id: 2, uid: 331606606766994432)
        try entityBuilder.addProperty(name: "id", type: PropertyType.long, flags: [.id], id: 1, uid: 2043845383559945216)
        try entityBuilder.addProperty(name: "text", type: PropertyType.string, id: 2, uid: 3134724612103213824)
        try entityBuilder.addProperty(name: "embedding", type: PropertyType.floatVector, flags: [.indexed], id: 3, uid: 7785552207533947392, indexId: 2, indexUid: 944669959825496320)
            .hnswParams(dimensions: 512, neighborsPerNode: nil, indexingSearchCount: nil, flags: nil, distanceType: nil, reparationBacklinkProbability: nil, vectorCacheHintSizeKB: nil)

        try entityBuilder.lastProperty(id: 3, uid: 7785552207533947392)
    }
}

extension NLVector {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { NLVector.id == myId }
    internal static var id: Property<NLVector, Id, Id> { return Property<NLVector, Id, Id>(propertyId: 1, isPrimaryKey: true) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { NLVector.text.startsWith("X") }
    internal static var text: Property<NLVector, String, Void> { return Property<NLVector, String, Void>(propertyId: 2, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { NLVector.embedding.isNotNil() }
    internal static var embedding: Property<NLVector, HnswIndexPropertyType, Void> { return Property<NLVector, HnswIndexPropertyType, Void>(propertyId: 3, isPrimaryKey: false) }

    fileprivate func __setId(identifier: ObjectBox.Id) {
        self.id = Id(identifier)
    }
}

extension ObjectBox.Property where E == NLVector {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .id == myId }

    internal static var id: Property<NLVector, Id, Id> { return Property<NLVector, Id, Id>(propertyId: 1, isPrimaryKey: true) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .text.startsWith("X") }

    internal static var text: Property<NLVector, String, Void> { return Property<NLVector, String, Void>(propertyId: 2, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .embedding.isNotNil() }

    internal static var embedding: Property<NLVector, HnswIndexPropertyType, Void> { return Property<NLVector, HnswIndexPropertyType, Void>(propertyId: 3, isPrimaryKey: false) }

}


/// Generated service type to handle persisting and reading entity data. Exposed through `NLVector.EntityBindingType`.
internal final class NLVectorBinding: ObjectBox.EntityBinding, Sendable {
    internal typealias EntityType = NLVector
    internal typealias IdType = Id

    internal required init() {}

    internal func generatorBindingVersion() -> Int { 1 }

    internal func setEntityIdUnlessStruct(of entity: EntityType, to entityId: ObjectBox.Id) {
        entity.__setId(identifier: entityId)
    }

    internal func entityId(of entity: EntityType) -> ObjectBox.Id {
        return entity.id.value
    }

    internal func collect(fromEntity entity: EntityType, id: ObjectBox.Id,
                                  propertyCollector: ObjectBox.FlatBufferBuilder, store: ObjectBox.Store) throws {
        let propertyOffset_text = propertyCollector.prepare(string: entity.text)
        let propertyOffset_embedding = propertyCollector.prepare(values: entity.embedding)

        propertyCollector.collect(id, at: 2 + 2 * 1)
        propertyCollector.collect(dataOffset: propertyOffset_text, at: 2 + 2 * 2)
        propertyCollector.collect(dataOffset: propertyOffset_embedding, at: 2 + 2 * 3)
    }

    internal func createEntity(entityReader: ObjectBox.FlatBufferReader, store: ObjectBox.Store) -> EntityType {
        let entity = NLVector()

        entity.id = entityReader.read(at: 2 + 2 * 1)
        entity.text = entityReader.read(at: 2 + 2 * 2)
        entity.embedding = entityReader.read(at: 2 + 2 * 3)

        return entity
    }
}



extension StsbRobertaVector: ObjectBox.__EntityRelatable {
    internal typealias EntityType = StsbRobertaVector

    internal var _id: EntityId<StsbRobertaVector> {
        return EntityId<StsbRobertaVector>(self.id.value)
    }
}

extension StsbRobertaVector: ObjectBox.EntityInspectable {
    internal typealias EntityBindingType = StsbRobertaVectorBinding

    /// Generated metadata used by ObjectBox to persist the entity.
    internal static let entityInfo = ObjectBox.EntityInfo(name: "StsbRobertaVector", id: 3)

    internal static let entityBinding = EntityBindingType()

    fileprivate static func buildEntity(modelBuilder: ObjectBox.ModelBuilder) throws {
        let entityBuilder = try modelBuilder.entityBuilder(for: StsbRobertaVector.self, id: 3, uid: 7849587746791637248)
        try entityBuilder.addProperty(name: "id", type: PropertyType.long, flags: [.id], id: 1, uid: 7667436301554191616)
        try entityBuilder.addProperty(name: "text", type: PropertyType.string, id: 2, uid: 8287835199751726336)
        try entityBuilder.addProperty(name: "embedding", type: PropertyType.floatVector, flags: [.indexed], id: 3, uid: 3522856394530866176, indexId: 3, indexUid: 8167600257001639680)
            .hnswParams(dimensions: 1024, neighborsPerNode: nil, indexingSearchCount: nil, flags: nil, distanceType: nil, reparationBacklinkProbability: nil, vectorCacheHintSizeKB: nil)

        try entityBuilder.lastProperty(id: 3, uid: 3522856394530866176)
    }
}

extension StsbRobertaVector {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { StsbRobertaVector.id == myId }
    internal static var id: Property<StsbRobertaVector, Id, Id> { return Property<StsbRobertaVector, Id, Id>(propertyId: 1, isPrimaryKey: true) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { StsbRobertaVector.text.startsWith("X") }
    internal static var text: Property<StsbRobertaVector, String, Void> { return Property<StsbRobertaVector, String, Void>(propertyId: 2, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { StsbRobertaVector.embedding.isNotNil() }
    internal static var embedding: Property<StsbRobertaVector, HnswIndexPropertyType, Void> { return Property<StsbRobertaVector, HnswIndexPropertyType, Void>(propertyId: 3, isPrimaryKey: false) }

    fileprivate func __setId(identifier: ObjectBox.Id) {
        self.id = Id(identifier)
    }
}

extension ObjectBox.Property where E == StsbRobertaVector {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .id == myId }

    internal static var id: Property<StsbRobertaVector, Id, Id> { return Property<StsbRobertaVector, Id, Id>(propertyId: 1, isPrimaryKey: true) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .text.startsWith("X") }

    internal static var text: Property<StsbRobertaVector, String, Void> { return Property<StsbRobertaVector, String, Void>(propertyId: 2, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .embedding.isNotNil() }

    internal static var embedding: Property<StsbRobertaVector, HnswIndexPropertyType, Void> { return Property<StsbRobertaVector, HnswIndexPropertyType, Void>(propertyId: 3, isPrimaryKey: false) }

}


/// Generated service type to handle persisting and reading entity data. Exposed through `StsbRobertaVector.EntityBindingType`.
internal final class StsbRobertaVectorBinding: ObjectBox.EntityBinding, Sendable {
    internal typealias EntityType = StsbRobertaVector
    internal typealias IdType = Id

    internal required init() {}

    internal func generatorBindingVersion() -> Int { 1 }

    internal func setEntityIdUnlessStruct(of entity: EntityType, to entityId: ObjectBox.Id) {
        entity.__setId(identifier: entityId)
    }

    internal func entityId(of entity: EntityType) -> ObjectBox.Id {
        return entity.id.value
    }

    internal func collect(fromEntity entity: EntityType, id: ObjectBox.Id,
                                  propertyCollector: ObjectBox.FlatBufferBuilder, store: ObjectBox.Store) throws {
        let propertyOffset_text = propertyCollector.prepare(string: entity.text)
        let propertyOffset_embedding = propertyCollector.prepare(values: entity.embedding)

        propertyCollector.collect(id, at: 2 + 2 * 1)
        propertyCollector.collect(dataOffset: propertyOffset_text, at: 2 + 2 * 2)
        propertyCollector.collect(dataOffset: propertyOffset_embedding, at: 2 + 2 * 3)
    }

    internal func createEntity(entityReader: ObjectBox.FlatBufferReader, store: ObjectBox.Store) -> EntityType {
        let entity = StsbRobertaVector()

        entity.id = entityReader.read(at: 2 + 2 * 1)
        entity.text = entityReader.read(at: 2 + 2 * 2)
        entity.embedding = entityReader.read(at: 2 + 2 * 3)

        return entity
    }
}


/// Helper function that allows calling Enum(rawValue: value) with a nil value, which will return nil.
fileprivate func optConstruct<T: RawRepresentable>(_ type: T.Type, rawValue: T.RawValue?) -> T? {
    guard let rawValue = rawValue else { return nil }
    return T(rawValue: rawValue)
}

// MARK: - Store setup

fileprivate func cModel() throws -> OpaquePointer {
    let modelBuilder = try ObjectBox.ModelBuilder()
    try MiniLMVector.buildEntity(modelBuilder: modelBuilder)
    try NLVector.buildEntity(modelBuilder: modelBuilder)
    try StsbRobertaVector.buildEntity(modelBuilder: modelBuilder)
    modelBuilder.lastEntity(id: 3, uid: 7849587746791637248)
    modelBuilder.lastIndex(id: 3, uid: 8167600257001639680)
    return modelBuilder.finish()
}

extension ObjectBox.Store {
    /// A store with a fully configured model. Created by the code generator with your model's metadata in place.
    ///
    /// # In-memory database
    /// To use a file-less in-memory database, instead of a directory path pass `memory:` 
    /// together with an identifier string:
    /// ```swift
    /// let inMemoryStore = try Store(directoryPath: "memory:test-db")
    /// ```
    ///
    /// - Parameters:
    ///   - directoryPath: The directory path in which ObjectBox places its database files for this store,
    ///     or to use an in-memory database `memory:<identifier>`.
    ///   - maxDbSizeInKByte: Limit of on-disk space for the database files. Default is `1024 * 1024` (1 GiB).
    ///   - fileMode: UNIX-style bit mask used for the database files; default is `0o644`.
    ///     Note: directories become searchable if the "read" or "write" permission is set (e.g. 0640 becomes 0750).
    ///   - maxReaders: The maximum number of readers.
    ///     "Readers" are a finite resource for which we need to define a maximum number upfront.
    ///     The default value is enough for most apps and usually you can ignore it completely.
    ///     However, if you get the maxReadersExceeded error, you should verify your
    ///     threading. For each thread, ObjectBox uses multiple readers. Their number (per thread) depends
    ///     on number of types, relations, and usage patterns. Thus, if you are working with many threads
    ///     (e.g. in a server-like scenario), it can make sense to increase the maximum number of readers.
    ///     Note: The internal default is currently around 120. So when hitting this limit, try values around 200-500.
    ///   - readOnly: Opens the database in read-only mode, i.e. not allowing write transactions.
    ///
    /// - important: This initializer is created by the code generator. If you only see the internal `init(model:...)`
    ///              initializer, trigger code generation by building your project.
    internal convenience init(directoryPath: String, maxDbSizeInKByte: UInt64 = 1024 * 1024,
                            fileMode: UInt32 = 0o644, maxReaders: UInt32 = 0, readOnly: Bool = false) throws {
        try self.init(
            model: try cModel(),
            directory: directoryPath,
            maxDbSizeInKByte: maxDbSizeInKByte,
            fileMode: fileMode,
            maxReaders: maxReaders,
            readOnly: readOnly)
    }
}

// swiftlint:enable all
