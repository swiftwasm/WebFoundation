// Copyright 2022 SwiftWasm project contributors.
// SPDX-License-Identifier: Apache-2.0

@_exported import Foundation

#if os(Linux)
    @_exported import FoundationNetworking
#endif

#if os(WASI)
    @_exported import WebFoundation
#endif
