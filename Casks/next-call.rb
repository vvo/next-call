cask "next-call" do
  version "0.2.0"
  sha256 "4168a01f7b576d71526fbdf340ab942bc47047a9aa8a1a5327d45d69fad57103"

  url "https://github.com/vvo/next-call/releases/download/v#{version}/NextCall.zip"
  name "Next Call"
  desc "Notification 1 minute before your next video call, with a one-click Join button"
  homepage "https://github.com/vvo/next-call"

  app "Next Call.app"

  postflight do
    system "xattr", "-cr", "#{appdir}/Next Call.app"
  end

  zap trash: [
    "~/Library/Preferences/dev.vvo.next-call.plist",
  ]
end
