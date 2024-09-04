//
//  KeyboardViewController.swift
//  Azerbaijani Turkish with arabic alphabet
//
//  Created by Soheil on 4/11/24.
//
//
import UIKit

class KeyboardViewController: UIInputViewController {

    var capsLockOn = false
    var alternativesView: UIView?
    var currentLongPressButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardKeys()
    }

    func setupKeyboardKeys() {
        let keyboardView = UIView()
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        keyboardView.backgroundColor = UIColor(red: 209/255, green: 212/255, blue: 217/255, alpha: 1.0) // Light gray background
        view.addSubview(keyboardView)

        // Constraints for keyboardView
        NSLayoutConstraint.activate([
            keyboardView.leftAnchor.constraint(equalTo: view.leftAnchor),
            keyboardView.rightAnchor.constraint(equalTo: view.rightAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            keyboardView.heightAnchor.constraint(equalToConstant: 216)  // Standard keyboard height
        ])

        let rows = [
            ["ض", "ص", "ث", "ق", "ف", "غ", "ع", "ه", "خ", "ح", "ج"],
            ["ش", "س", "ی", "ب", "ل", "ا", "ت", "ن", "م", "ک", "گ"],
            ["ظ", "ط", "ژ", "ز", "ر", "ذ", "د", "پ", "و", "چ", "⌫"],
            ["123", "😀", "بوشلوق", "⌄", "↲"]
        ]
        var previousRow: UIStackView?

        let buttonHeight: CGFloat = 45
        let rowSpacing: CGFloat = 6 // Reduced spacing between rows

        for (index, row) in rows.enumerated() {
            let rowStackView = createRowStackView(keys: row, isLastRow: index == rows.count - 1)
            keyboardView.addSubview(rowStackView)

            rowStackView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                rowStackView.leftAnchor.constraint(equalTo: keyboardView.leftAnchor, constant: 3),
                rowStackView.rightAnchor.constraint(equalTo: keyboardView.rightAnchor, constant: -3),
                rowStackView.heightAnchor.constraint(equalToConstant: buttonHeight)
            ])

            if let previousRow = previousRow {
                NSLayoutConstraint.activate([
                    rowStackView.topAnchor.constraint(equalTo: previousRow.bottomAnchor, constant: rowSpacing)
                ])
            } else {
                NSLayoutConstraint.activate([
                    rowStackView.topAnchor.constraint(equalTo: keyboardView.topAnchor, constant: rowSpacing)
                ])
            }

            previousRow = rowStackView
        }
    }

    func createRowStackView(keys: [String], isLastRow: Bool) -> UIStackView {
        let stackView = UIStackView()
        stackView.distribution = .fillProportionally
        stackView.spacing = 6
        stackView.alignment = .fill

        for key in keys {
            let button = createButton(title: key, isSpecialKey: isLastRow || key == "⌫")
            stackView.addArrangedSubview(button)
            
            if isLastRow {
                if key == "بوشلوق" {
                    button.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.5).isActive = true
                } else {
                    button.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.15).isActive = true
                }
            }
            
            // Ensure all buttons have the same height
            button.heightAnchor.constraint(equalTo: stackView.heightAnchor).isActive = true
        }

        return stackView
    }

    func createButton(title: String, isSpecialKey: Bool) -> UIButton {
        let button = UIButton(type: .system)
        
        if title == "⌫" {
            let deleteImage = UIImage(systemName: "delete.left")
            button.setImage(deleteImage, for: .normal)
            button.tintColor = .black
        } else {
            button.setTitle(title, for: .normal)
        }
        
        button.layer.cornerRadius = 5
        button.translatesAutoresizingMaskIntoConstraints = false
        
        if isSpecialKey {
            button.backgroundColor = UIColor(red: 172/255, green: 179/255, blue: 188/255, alpha: 1.0) // Darker gray for special keys
            button.setTitleColor(.black, for: .normal)
        } else {
            button.backgroundColor = .white
            button.setTitleColor(.black, for: .normal)
        }
        
        button.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .regular)
        button.addTarget(self, action: #selector(keyPressed(_:)), for: .touchUpInside)

        // Add shadow effect
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowOpacity = 0.1
        button.layer.shadowRadius = 0.5

        // Add long press gesture recognizer
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.3 // Adjust as needed
        button.addGestureRecognizer(longPressGesture)

        return button
    }

    @objc func keyPressed(_ sender: UIButton) {
        if let title = sender.title(for: .normal) {
            switch title {
            case "بوشلوق":
                textDocumentProxy.insertText(" ")
            case "↲":
                textDocumentProxy.insertText("\n")
            case "123":
                // TODO: Implement number pad
                break
            case "😀":
                // TODO: Implement emoji keyboard
                break
            case "⌄":
                // TODO: Implement keyboard options
                break
            default:
                textDocumentProxy.insertText(title)
            }
        } else if sender.image(for: .normal) != nil {
            // This is the delete button
            textDocumentProxy.deleteBackward()
        }
    }

    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard let button = gesture.view as? UIButton, let title = button.title(for: .normal) else { return }
        
        switch gesture.state {
        case .began:
            currentLongPressButton = button
            showAlternatives(for: title, from: button)
        case .changed:
            updateSelectedAlternative(at: gesture.location(in: alternativesView))
        case .ended:
            if let selectedAlternative = getSelectedAlternative(at: gesture.location(in: alternativesView)) {
                textDocumentProxy.insertText(selectedAlternative)
            }
            hideAlternatives()
        case .cancelled:
            hideAlternatives()
        default:
            break
        }
    }

    func showAlternatives(for key: String, from sourceButton: UIButton) {
        let alternatives = getAlternatives(for: key)
        guard !alternatives.isEmpty else { return }
        
        // Remove existing alternatives view if any
        alternativesView?.removeFromSuperview()
        
        let alternativesView = UIView()
        alternativesView.backgroundColor = UIColor(white: 0.9, alpha: 0.9)
        alternativesView.layer.cornerRadius = 8
        alternativesView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(alternativesView)
        
        // Position the alternatives view above the source button
        NSLayoutConstraint.activate([
            alternativesView.bottomAnchor.constraint(equalTo: sourceButton.topAnchor, constant: -8),
            alternativesView.centerXAnchor.constraint(equalTo: sourceButton.centerXAnchor),
            alternativesView.heightAnchor.constraint(equalToConstant: sourceButton.frame.height),
            alternativesView.widthAnchor.constraint(equalToConstant: CGFloat(alternatives.count) * sourceButton.frame.width)
        ])
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = 1
        stackView.translatesAutoresizingMaskIntoConstraints = false
        alternativesView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: alternativesView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: alternativesView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: alternativesView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: alternativesView.trailingAnchor)
        ])
        
        for alternative in alternatives {
            let altButton = createButton(title: alternative, isSpecialKey: false)
            altButton.isUserInteractionEnabled = false
            stackView.addArrangedSubview(altButton)
        }
        
        self.alternativesView = alternativesView
    }

    func hideAlternatives() {
        alternativesView?.removeFromSuperview()
        alternativesView = nil
        currentLongPressButton = nil
    }

    func updateSelectedAlternative(at location: CGPoint) {
        guard let alternativesView = alternativesView else { return }
        
        for case let button as UIButton in alternativesView.subviews.first?.subviews ?? [] {
            let isSelected = button.frame.contains(location)
            button.backgroundColor = isSelected ? .lightGray : .white
        }
    }

    func getSelectedAlternative(at location: CGPoint) -> String? {
        guard let alternativesView = alternativesView else { return nil }
        
        for case let button as UIButton in alternativesView.subviews.first?.subviews ?? [] {
            if button.frame.contains(location) {
                return button.title(for: .normal)
            }
        }
        
        return nil
    }

    func getAlternatives(for key: String) -> [String] {
        switch key {
        case "ی":
            return ["ی", "ئ", "ي"]
        case "ا":
            return ["ا", "آ", "أ", "إ"]
        // Add more cases for other keys as needed
        default:
            return []
        }
    }

    func updateKeys() {
        // For Arabic script, we don't need to change case
        // This function can be left empty or removed
    }
}
