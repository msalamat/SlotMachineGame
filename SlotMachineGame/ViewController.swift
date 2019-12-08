//
//  ViewController.swift
//  SlotMachineGame
//
//  Created by Mengjun Wang on 2019-11-29.
//  Copyright © 2019 ivan. All rights reserved.
//

import UIKit
import AVFoundation
import PopupDialog

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    
    @IBOutlet weak var spinPickerView: UIPickerView!
    @IBOutlet weak var betLabel: UILabel!
    @IBOutlet weak var wonLabel: UILabel!
    @IBOutlet weak var spinButton: UIButton!
    @IBOutlet weak var jackpotLabel: UILabel!
    
    @IBOutlet weak var jackPotStack: UIStackView!
    
    
    
    var bet = 0
    var won = 0
    var jackpot = 100
    var timer:Timer?
    var finalPositions = [0,0,0]
    var currents = [0,0,0]
    var rounds = 0
    var winSound: AVAudioPlayer?
    var backgroundSound: AVAudioPlayer?
    var leverSound: AVAudioPlayer?
    var spinSound: AVAudioPlayer?
    var isRunning = false
    
    let images = [
        [UIImage(named: "1"), UIImage(named: "2"), UIImage(named: "3")],
        [UIImage(named: "1"), UIImage(named: "2"), UIImage(named: "3")],
        [UIImage(named: "1"), UIImage(named: "2"), UIImage(named: "3")],
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        spinPickerView.dataSource = self
        spinPickerView.delegate = self
        spinPickerView.selectRow(2, inComponent: 0, animated: false)
        spinPickerView.selectRow(2, inComponent: 1, animated: false)
        spinPickerView.selectRow(2, inComponent: 2, animated: false)

        betLabel.text = String(bet)
        wonLabel.text = String(won)
        spinButton.isEnabled = false
        self.view.backgroundColor = .black
        
        var path = Bundle.main.path(forResource: "winningSound.mp3", ofType:nil)!
        var url = URL(fileURLWithPath: path)
        do {
            winSound = try AVAudioPlayer(contentsOf: url)
            
        } catch {
            // couldn't load file :(
        }
        
        path = Bundle.main.path(forResource: "08 Casino Night Zone.mp3", ofType:nil)!
        url = URL(fileURLWithPath: path)
        do {
            backgroundSound = try AVAudioPlayer(contentsOf: url)
            backgroundSound?.numberOfLoops = -1
            backgroundSound?.play()
        } catch {
            // couldn't load file :(
        }
        
        path = Bundle.main.path(forResource: "spinningSound.mp3", ofType:nil)!
        url = URL(fileURLWithPath: path)
        do {
            spinSound = try AVAudioPlayer(contentsOf: url)
            spinSound?.numberOfLoops = -1
        } catch {
            // couldn't load file :(
        }
        
        path = Bundle.main.path(forResource: "lever.mp3", ofType:nil)!
        url = URL(fileURLWithPath: path)
        do {
            leverSound = try AVAudioPlayer(contentsOf: url)
        } catch {
            // couldn't load file :(
        }
        
        
        //        spin()
    }
    
    
    //MARK: - PICKER VIEW
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return images.count
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return images[component].count*100
    }
    
    //    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    //        return images[component][row]
    //    }
    //
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        
        imageView.image = images[component][row % images.count]
        
        return imageView
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return CGFloat(80)
    }
    
    func resetSpinButton() {
        if !isRunning {
            spinButton.isEnabled = true
        }
    }
    
    func showJackpotDialog() {
        timer?.invalidate()
        let title = "JACKPOT WON! $\(jackpot)"
        let message = "Good work!"
        let image = UIImage(named: "jackpot-1")
        // Create the dialog
        let popup = PopupDialog(title: title, message: message, image: image)
        let buttonOne = DefaultButton(title: "Exit", height: 100) {
            print("Exit")
        }
        popup.addButtons([buttonOne])
        // Present dialog
        self.present(popup, animated: true, completion: nil)
    }
    
    
    //MARK: - UI EVENTS
    @IBAction func fiveTapped(_ sender: UIButton) {
        resetSpinButton()
        updateBet(to: bet + 5)
    }
    
    
    @IBAction func tenTapped(_ sender: UIButton) {
        resetSpinButton()
        updateBet(to: bet + 10)
    }
    
    @IBAction func twentyFiveTapped(_ sender: UIButton) {
        resetSpinButton()
        updateBet(to: bet + 25)
    }
    
    @IBAction func startSpinTapped(_ sender: UIButton) {
        spinButton.isEnabled = false
        isRunning = true
        rounds += 1
        updateJackpot(add: bet)
        updateBet(to: 0)
        resetSpinVariable()
        leverSound?.play()
        spinSound?.play()
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true, block: {
            [weak self](_) in
            self?.spin()
        })
    }
    
    
    //MARK: - HELPER FUNCTION
    private func updateBet(to amount:Int){
        bet = amount
        betLabel.text = String(bet)
    }
    
    private func updateWon(to amount:Int){
        won = amount
        wonLabel.text = String(won)
    }
    
    private func updateJackpot(add amount:Int) {
        jackpot += amount
        jackpotLabel.text = String(jackpot)
    }
    
    private func resetSpinVariable() {
        print("rounds: \(rounds)")
        if rounds < 11 {
            let firstPostion = Int(arc4random_uniform(UInt32(images[0].count * 100/6)))
            finalPositions = [
                firstPostion + 30, //0 ... 50
                firstPostion + 40,  // 50...100
                firstPostion + 50   // 100...150
            ]
        }else {
            let randomIndex = Int(arc4random_uniform(UInt32(images[0].count * 100/3)))
            finalPositions = [randomIndex, randomIndex, randomIndex]
        }
        
        currents = [0,0,0]
    }
    
    
    
    private func spin() {
        
        if currents[2] == finalPositions[2] {
            timer?.invalidate()
            isRunning = false
            spinSound?.stop()
            print("currents: \(currents)")
            print("finals: \(finalPositions)")
            
            
            if currents[0] % 3 == currents[1] % 3 && currents[1] % 3 == currents[2] % 3 {
                rounds = 0
                winSound?.play()
                print("win")
                showJackpotDialog()
            }else {
                print("lose")
            }
            if let bet = Int(betLabel.text ?? "0"), bet > 0 {
                spinButton.isEnabled = true
            }
        }
        
        for col in 0...2 {
            
            if currents[col] < finalPositions[col] {
                spinPickerView.selectRow(currents[col], inComponent: col, animated: true)
                currents[col] += 1
            }
        }
        
    }
    
    private func wonJackpot() {
        
    }
    
    @IBAction func translate(_ sender: UIButton) {
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
            self.move(button: sender, yPos: 100)
        }, completion: { finished in
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                self.move(button: sender, yPos: -100)
            }, completion: { finished in
                
            })
        })
    }
    
    func move(button : UIButton, yPos : Int) {
        button.frame = CGRect(x: button.frame.origin.x, y: button.frame.origin.y + CGFloat(yPos), width: button.frame.width, height: button.frame.height)
        //handleBar.frame = CGRect(x: handleBar.frame.origin.x, y: handleBar.frame.origin.y + CGFloat(yPos), width: handleBar.frame.width, height: handleBar.frame.height - CGFloat(yPos))
    }
}

