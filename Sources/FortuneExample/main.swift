import ImplicitReturn
import Foundation

@ImplicitReturn
func fortune(_ number: Int) -> String {
    print("Requesting fortune for \(number)")
    switch number {
        case 1, 3, 5:
            print("Warning: Support for odd numbers is unstable")
            if number == 3 {
                "You have a long and prosperous future"
            } else {
                "Your future looks bleak"
            }
        case 2, 4, 6:
            if number == 6 {
                "You must watch your back tomorrow (good luck...)"
            } else {
                "Your shoes will develop an untimely hole"
            }
        default:
            print("Warning: I've never encountered \(number) before")
            "Spaghetti will fall, meatballs will rise"
    }
}

let number = Int.random(in: 1...8)
let yourFortune = fortune(number)
print("Fortune:", yourFortune)
