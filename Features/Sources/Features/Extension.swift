//
//  File.swift
//  
//
//  Created by Yang Xu on 2022/11/29.
//

import ComposableArchitecture
import Foundation
import SwiftUI

public extension View {
    /// 当 store 的 state 变为非可选时，弹出 Sheet。当 state 为 nil 时关闭 Sheet
    ///
    /// 多数情况下在 sheet 的视图代码中，需要自行使用 dismissAction 来取消视图（ 将 state 转换为 nil ），在用户使用手势下滑取消时，会尝试发送 dismissAction
    ///
    /// - Parameters:
    ///   - store: A store that describes if the sheet is shown or dismissed.
    ///   - dismissAction: An action to send when the sheet is dismissed ,usually when the user swipes down with a gesture, it is sent
    ///   - onDismiss: a closure called when sheet dismiss
    ///   - content: content of sheet view
    @ViewBuilder
    func sheet<State, Action, Content>(
        _ store: Store<State?, Action>,
        dismissAction: Action,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (Store<State, Action>) -> Content
    ) -> some View where State: Equatable, Action: Equatable, Content: View {
        modifier(OptionalStateSheetModifier(store: store, dismissAction: dismissAction, onDismiss: onDismiss, content: content))
    }

    /// 当 store 的 state 变为非可选时，弹出 Full Screen Cover。当 state 为 nil 时关闭 Full Screen Cover
    ///
    /// 在 FullScreenCover 的视图代码中，需要自行使用 dismissAction 来取消视图（ 将 state 转换为 nil ）
    ///
    /// - Parameters:
    ///   - store: A store that describes if the sheet is shown or dismissed.
    ///   - dismissAction: 在 fullScreenCover 中并无作用，主要是为了与 sheet 兼容
    ///   - onDismiss: a closure called when sheet dismiss
    ///   - content: content of sheet view
    @ViewBuilder
    func fullScreenCover<State, Action, Content>(
        _ store: Store<State?, Action>,
        dismissAction: Action,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (Store<State, Action>) -> Content
    ) -> some View where State: Equatable, Action: Equatable, Content: View {
        modifier(OptionalStateFullScreenCoverModifier(store: store, dismissAction: dismissAction, onDismiss: onDismiss, content: content))
    }
}

struct OptionalStateSheetModifier<State, Action, SheetView>: ViewModifier where State: Equatable, Action: Equatable, SheetView: View {
    @ObservedObject var viewStore: ViewStore<State?, Action>
    let dismissAction: Action
    let onDismiss: (() -> Void)?
    let sheetView: (Store<State, Action>) -> SheetView
    let store: Store<State?, Action>
    init(store: Store<State?, Action>, dismissAction: Action, onDismiss: (() -> Void)?, content: @escaping (Store<State, Action>) -> SheetView) {
        self.viewStore = ViewStore(store)
        self.dismissAction = dismissAction
        self.onDismiss = onDismiss
        self.sheetView = content
        self.store = store
    }

    func body(content: Content) -> some View {
        content.sheet(isPresented: viewStore.binding(send: dismissAction).isPresent(dismiss: {
            if viewStore.state != nil {
                viewStore.send(dismissAction)
            }
        }), onDismiss: {
            onDismiss?()
        }) {
            IfLetStore(store) { store in
                sheetView(store)
            }
        }
    }
}

struct OptionalStateFullScreenCoverModifier<State, Action, SheetView>: ViewModifier where State: Equatable, Action: Equatable, SheetView: View {
    @ObservedObject var viewStore: ViewStore<State?, Action>
    let dismissAction: Action
    let onDismiss: (() -> Void)?
    let sheetView: (Store<State, Action>) -> SheetView
    let store: Store<State?, Action>
    init(store: Store<State?, Action>, dismissAction: Action, onDismiss: (() -> Void)?, content: @escaping (Store<State, Action>) -> SheetView) {
        self.viewStore = ViewStore(store)
        self.dismissAction = dismissAction
        self.onDismiss = onDismiss
        self.sheetView = content
        self.store = store
    }

    func body(content: Content) -> some View {
        content.fullScreenCover(isPresented: viewStore.binding(send: dismissAction).isPresent(dismiss: {
            if viewStore.state != nil {
                viewStore.send(dismissAction)
            }
        }), onDismiss: {
            onDismiss?()
        }) {
            IfLetStore(store) { store in
                sheetView(store)
            }
        }
    }
}


private extension Binding {
    func isPresent<Wrapped>(dismiss: @escaping () -> Void) -> Binding<Bool> where Value == Wrapped? {
        .init(
            get: { self.wrappedValue != nil },
            set: { isPresent, _ in
                guard !isPresent else { return }
                dismiss()
            }
        )
    }
}
