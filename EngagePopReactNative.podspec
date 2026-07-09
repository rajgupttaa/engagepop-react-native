require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "EngagePopReactNative"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = "https://engagepop.com"
  s.license      = "MIT"
  s.authors      = { "EngagePop" => "support@engagepop.com" }
  s.platforms    = { :ios => "13.0" }
  s.source       = { :git => "https://github.com/rajgupttaa/engagepop-react-native.git", :tag => s.version }
  s.source_files = "ios/**/*.{h,m,mm,swift}"

  s.dependency "React-Core"
  # The native iOS SDK does the real work.
  s.dependency "EngagePop"
end
