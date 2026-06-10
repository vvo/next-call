cask "next-call" do
  version "0.2.2"
  sha256 "e116d483a7cf15d69d76fb83dd6f44c47058664ae0eb527463abb92fddfe85fe"

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
