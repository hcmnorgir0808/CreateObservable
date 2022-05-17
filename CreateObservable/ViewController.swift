//
//  ViewController.swift
//  CreateObservable
//
//  Created by 岩本康孝 on 2022/05/13.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


}

//struct Observable<T> {
//    // Observalbeにプロパティを用意し値を保持させる(ストリームに流すため)
//    // 保持する型をIntに限定しないのでジェネリクスとて型パラメータをElementを指定(実際に動作するときに決まる)
//    let element: T
//}
//
//extension Observable {
//    static func just(_ element: T) -> Observable {
//        // 作って返すだけ
//        // justオペレータを呼び出すときにObservableへ要素を保持させるようにする
//        Observable(element: element)
//    }
//}
//
//extension Observable {
//    func subscribe(
//        onNext: ((T) -> ())? = nil,
//        onCompleted: (() -> ())? = nil
//    ) {
//        // onNextで固定値を返していたのをやめ、保持している要素を渡すようにした
//        onNext?(element)
//        // そのまま終了するだけ
//        onCompleted?()
//    }
//}
//

enum Event<Element> {
    case next(Element)
    case completed
}

// イベントを通知するonメソッドを持つプロトコルとしてObserverTypeを作成
protocol ObserverType {
    associatedtype Element
    func on(_ event: Event<Element>)
}
// 監視時のイベントを保持しイベント検知時にイベントを実行する型を作る
struct AnyObserver<Element>: ObserverType {
    private let eventHandler: (Event<Element>) -> ()

    init(eventHandler: @escaping (Event<Element>) -> ()) {
        self.eventHandler = eventHandler
    }

    func on(_ event: Event<Element>) {
        // イベントを検知すると監視時のイベントを実行させる
        eventHandler(event)
    }
}

class Sink<Observer: ObserverType> {
    private let observer: Observer

    init(observer: Observer) {
        self.observer = observer
    }

    final func forwardOn(_ event: Event<Observer.Element>) {
        observer.on(event)
    }

}

class Observable<Element> {
    // クロージャによる購読処理
    func subscribe(
        onNext: ((Element) -> ())? = nil,
        onCompleted: (() -> ())? = nil
    ) {
        fatalError("subscribeが不適切に使用された")
    }

    // AnyObserver型による購読処理
    // Observableのsubscribeメソッドは引数にObserverTypeを指定するようにする
    // ObservableTypeのElementとObservableのElementが同一であるような制限にする
    func subscribe<Observer: ObserverType>(_ observer: Observer) where Observer.Element == Element {
        preconditionFailure("このメソッドが呼ばれると実装ミス")
    }
}

class Just<Element>: Observable<Element> {
    private let element: Element

    init(element: Element) {
        self.element = element
    }

    override func subscribe(
        onNext: ((Element) -> ())? = nil,
        onCompleted: (() -> ())? = nil
    ) {
        // onNextとonCompletedを引数でもらってくるので、それに対応したobserverを定義
        let observer = AnyObserver<Element> { event in
            switch event {
            case .next(let value):
                onNext?(value)
            case .completed:
                onCompleted?()
            }
        }
        subscribe(observer)
    }

    override func subscribe<Observer: ObserverType>(_ observer: Observer) where Observer.Element == Element {
        observer.on(.next(element))
        observer.on(.completed)
    }
}

extension Observable {
    static func just(_ element: Element) -> Observable {
        Just(element: element)
    }

    static func of(_ elements: Element...) -> Observable<Element> {
        // ofでもObservableを返す
        ObservableSequence(elements: elements)
    }
}

// ジェネリクスを2つ定義(Sequence, Element)
class ObservableSequence<Sequence: Swift.Sequence, Element>: Observable<Element> {
    let elements: Sequence

    init(elements: Sequence) {
        // elementsはSequence型を受け取る
        self.elements = elements
    }

    override func subscribe<Observer>(_ observer: Observer) where Element == Observer.Element, Observer : ObserverType {
        // 保持している要素をループさせObserverへ通知し、最後に完了を流す
        let sink = ObservableSequenceSink(parent: self, observer: observer)
        sink.run()
    }

    private class ObservableSequenceSink<Sequence: Swift.Sequence, Observer: ObserverType, Element>: Sink<Observer> {
        private let parent: ObservableSequence<Sequence, Element>

        init(parent: ObservableSequence<Sequence, Element>, observer: Observer) {
            self.parent = parent
            super.init(observer: observer)
        }

        func run() {
            parent.elements.forEach { element in
                if let element = element as? Observer.Element {
                    forwardOn(.next(element))
                }
            }

            forwardOn(.completed)
        }
    }
}

extension Observable {
    // mapオペレータを作り専用のObservableであるMapを返す
    func map(
        _ handler: (@escaping (_ element: Element) -> Element)
    ) -> Observable<Element> {
        // ・外部から与える変換処理を行うクロージャはtransformという変数名とする
        // ・mapオペレータを作り、専用のObservableであるMapを返すようにする
        // ・Mapにはオペレータを呼び出したObservable自身をsource、変換用のクロージャをtransform変数として渡す
        Map(source: self, transform: handler)
    }
}

class Map<SourceType, ResultType>: Observable<ResultType> {
    typealias Element = ResultType
    typealias Transform = (SourceType) -> ResultType

    // 上流のmapオペレータをつかうObservable
    private let source: Observable<SourceType>
    // 変換用のクロージャ
    private let transform: Transform

    init(source: Observable<SourceType>, transform: @escaping Transform) {
        self.source = source
        self.transform = transform
    }

    override func subscribe<Observer>(_ observer: Observer) where ResultType == Observer.Element, Observer : ObserverType {
        let sink = MapSink(transform: transform, observer: observer)
        // 上流のObservableが下流で作られるMapSinkのObservableをsubscribeする
        source.subscribe(sink)
    }

    private class MapSink<SourceType, Observer: ObserverType>: Sink<Observer>, ObserverType {
        typealias Element = SourceType
        typealias Transform = (SourceType) throws -> ResultType

        typealias ResultType = Observer.Element

        private let transform: Transform

        init(transform: @escaping Transform, observer: Observer) {
            self.transform = transform
            super.init(observer: observer)
        }

        func on(_ event: Event<SourceType>) {
            switch event {
            case .next(let element):
                let mappedElement = try! self.transform(element)
                forwardOn(.next(mappedElement))
            case .completed:
                forwardOn(.completed)
            }
        }
    }
}
