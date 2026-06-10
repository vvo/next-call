cask "next-call" do
  version "0.2.1"
  sha256 "fe402a8f886ad07e9d85f743c3e9bc3fc5dc85c1042152d21e977041785dad39"

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
