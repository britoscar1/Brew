# Brew

Brew is an iOS coffee journal for people who brew at home. You save your coffees, log the settings of each brew (V60, AeroPress, French Press or espresso), time it, rate the cup, and get a suggestion for what to change next time. The suggestion changes one variable at a time, so you can tell what made the difference.

Everything is stored on the device with SwiftData. There is no account, no network and no third-party dependency.

Built with SwiftUI for the MDI1 capstone at San Diego Global Knowledge University.

## Running the project

You need a Mac with Xcode that includes the iOS 26.5 SDK or later.

1. Clone the repository:
   ```
   git clone https://github.com/britoscar1/Brew.git
   ```
2. Open `Brew.xcodeproj` in Xcode.
3. Choose the `Brew` scheme and an iPhone simulator (any iPhone running iOS 26.5 or later).
4. Press Cmd+R.

To run the tests, press Cmd+U.

The first launch starts with an empty library. Open the Library tab and add a coffee, then go back to the Brew tab to start a brew.
