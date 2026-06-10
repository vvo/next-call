cask "next-call" do
  version "0.1.0"
  sha256 "885658449add1ed88d7b73faa01adeba97bb81363f162d29ed085a6e2f31b366"

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
