//
//  ViewController.swift
//  ReactiveGame
//
//  Created by Aubrey Goodman on 9/23/16.
//  Copyright © 2016 Aubrey Goodman. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa


class ViewController: UIViewController {

  private let gravity : Double = 50
  
  private let disposeBag : DisposeBag = DisposeBag()
  private let x : Variable<Double> = Variable<Double>(0)
  private let y : Variable<Double> = Variable<Double>(0)
  private let u : Variable<Double> = Variable<Double>(0)
  private let v : Variable<Double> = Variable<Double>(0)
  private let uKick : Variable<Double> = Variable<Double>(0)
  private let vKick : Variable<Double> = Variable<Double>(0)
  
  @IBOutlet var sprite : UIView?
  
  override func viewDidLoad() {
    super.viewDidLoad()

    let interval : Double = 0.1
    let timer : Observable<Int8> = Observable.interval(interval, scheduler: MainScheduler.instance)
    
    //////////////////////////
    // X Axis Begin
    
    
    // initial x-axis velocity
    let u0 : Double = 0
    
    // u is derived from timer
    let uBase = timer
      .map { (tick: Int8) in interval }
      .scan(u0) { (total, value) in total }
        
    Observable.combineLatest(uBase, uKick.asObservable()) { $0 }
      // bind the result to a unique variable.
      // this means the latest event on u is always "current state"
      .observeOn(MainScheduler.instance)
      .subscribeNext { [unowned self] (u0, u1) in
        self.u.value = u0 + u1
      }
      .addDisposableTo(disposeBag)

    let x0 : Double = 100
    
    // y position is derived from velocity
    u
      .asObservable()
      .scan(x0) { total, value in total + value * interval }
      .subscribeNext {
        self.x.value = $0
      }
      .addDisposableTo(disposeBag)
    
    // X Axis End
    //////////////////////////
    
    
    //////////////////////////
    // Y Axis Begin
    
    // initial y-axis velocity
    let v0 : Double = 0
    
    // velocity is derived from timer
    let vBase = timer
      // tick is an integer counter that increases.
      // we are ignoring it and using the interval instead
      .map { (tick: Int8) in
        interval
      }
      // pattern demands consideration of initial state,
      // so we inject it into the scan seed
      .scan(v0) { (total, value) in
        total + self.gravity * interval
    }
    
    Observable.combineLatest(vBase, vKick.asObservable()) { $0 }
      // bind the result to a unique variable.
      // this means the latest event on v is always "current state"
      .observeOn(MainScheduler.instance)
      .subscribeNext { [unowned self] (v0, v1) in
        self.v.value = v0 + v1
      }
      .addDisposableTo(disposeBag)
    
    // y position is derived from velocity
    let y0 : Double = 200
    v
      .asObservable()
      .scan(y0) { (total, value) in total + value * interval }
      .subscribeNext { [unowned self] in
        self.y.value = $0
      }
      .addDisposableTo(disposeBag)
    
    // Y Axis End
    //////////////////////////

    
    let center = Observable
      .combineLatest(x.asObservable(), y.asObservable(), u.asObservable(), v.asObservable()) { $0 }
    
    center
      .asObservable()
      .map { (x, y, u, v) in return (x, y) }
      .map { (x: Double, y: Double) -> CGPoint in CGPointMake(CGFloat(x), CGFloat(y)) }
      .subscribeNext { center in
        UIView.animateWithDuration(interval) {
          self.sprite?.center = center
        }
      }
      .addDisposableTo(disposeBag)

  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @IBAction func tap(recognizer: UIGestureRecognizer) {
    // determine delta between current position and tap position
    let position = recognizer.locationOfTouch(0, inView: self.view)
    
    let dx = Double(position.x) - x.value
    let dy = Double(position.y) - y.value
    
    // kick
    self.uKick.value = self.uKick.value + dx
    self.vKick.value = self.vKick.value + dy
  }
  
}

