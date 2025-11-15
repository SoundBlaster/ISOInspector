#if canImport(Combine)
  public enum ParseTreeStoreState: Equatable {
    case idle
    case parsing
    case finished
    case failed(String)
  }
#endif
