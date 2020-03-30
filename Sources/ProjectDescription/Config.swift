import Foundation

public typealias TuistConfig = Config

/// This model allows to configure Tuist.
public struct Config: Codable, Equatable {
    /// Contains options related to the project generation.
    ///
    /// - xcodeProjectName(TemplateString): When passed, Tuist generates the project with the specific name on disk instead of using the project name.
    /// - organizationName(String): When passed, Tuist generates the project with the specific organization name.
    /// - disableAutogeneratedSchemes: When passed, Tuist generates the project only with custom specified schemes, autogenerated default schemes are skipped
    public enum GenerationOptions: Encodable, Decodable, Equatable {
        case xcodeProjectName(TemplateString)
        case organizationName(String)
        case disableAutogeneratedSchemes
    }

    /// Generation options.
    public let generationOptions: [GenerationOptions]

    /// List of Xcode versions that the project supports.
    public let compatibleXcodeVersions: CompatibleXcodeVersions

    /// URL to the server that caching and insights will interact with.
    public let cloudURL: String?

    /// Initializes the tuist cofiguration.
    ///
    /// - Parameters:
    ///   - compatibleXcodeVersions: List of Xcode versions the project is compatible with.
    ///   - cloudURL: URL to the server that caching and insights will interact with.
    ///   - generationOptions: List of options to use when generating the project.
    public init(compatibleXcodeVersions: CompatibleXcodeVersions = .all,
                cloudURL: String? = nil,
                generationOptions: [GenerationOptions]) {
        self.compatibleXcodeVersions = compatibleXcodeVersions
        self.generationOptions = generationOptions
        self.cloudURL = cloudURL
        dumpIfNeeded(self)
    }
}

extension Config.GenerationOptions {
    enum CodingKeys: String, CodingKey {
        case xcodeProjectName, organizationName, disableAutogeneratedSchemes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.allKeys.contains(.xcodeProjectName), try container.decodeNil(forKey: .xcodeProjectName) == false {
            var associatedValues = try container.nestedUnkeyedContainer(forKey: .xcodeProjectName)
            let templateProjectName = try associatedValues.decode(TemplateString.self)
            self = .xcodeProjectName(templateProjectName)
            return
        }
        if container.allKeys.contains(.organizationName), try container.decodeNil(forKey: .organizationName) == false {
            var associatedValues = try container.nestedUnkeyedContainer(forKey: .organizationName)
            let organizationName = try associatedValues.decode(String.self)
            self = .organizationName(organizationName)
            return
        }
        if try container.decode(Bool.self, forKey: .disableAutogeneratedSchemes) {
            self = .disableAutogeneratedSchemes
            return
        }
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown enum case"))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .xcodeProjectName(templateProjectName):
            var associatedValues = container.nestedUnkeyedContainer(forKey: .xcodeProjectName)
            try associatedValues.encode(templateProjectName)
        case let .organizationName(name):
            var associatedValues = container.nestedUnkeyedContainer(forKey: .organizationName)
            try associatedValues.encode(name)
        case .disableAutogeneratedSchemes:
            try container.encode(true, forKey: .disableAutogeneratedSchemes)
        }
    }
}

public func == (lhs: TuistConfig, rhs: TuistConfig) -> Bool {
    guard lhs.generationOptions == rhs.generationOptions else { return false }
    return true
}

public func == (lhs: TuistConfig.GenerationOptions, rhs: TuistConfig.GenerationOptions) -> Bool {
    switch (lhs, rhs) {
    case let (.xcodeProjectName(lhs), .xcodeProjectName(rhs)):
        return lhs.rawString == rhs.rawString
    case let (.organizationName(lhs), .organizationName(rhs)):
        return lhs == rhs
    case (.disableAutogeneratedSchemes, .disableAutogeneratedSchemes):
        return true
    default:
        return false
    }
}
