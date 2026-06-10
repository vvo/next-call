cask "next-call" do
  version "0.1.1"
  sha256 "a15b61d97acf44113cfdf6a29fc270a768c9f2d795d228553af093ead63e9652"

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
