Pod::Spec.new do |s|

s.name         = "TMIndexBar"
s.version      = "0.2"
s.summary      = "TMIndexBar is a customizable index bar for UITableView with LTR & RTL support"

s.description  = "TMIndexBar provides a customizable interface for displaying an index bar on the right or left side of a UITableView. BarAppearanceBuilder can be used to fully customize the index bar"

s.license      = "MIT"

s.author             = { "" => "tafveez@live.com" }

s.homepage = "https://github.com/tafveezm/TMIndexBar"

s.platform     = :ios, "10.0"

s.source       = { :git => "https://github.com/tafveezm/TMIndexBar.git", :tag => '0.2' }

s.source_files  = "TMIndexBar", "TMIndexBar/**/*.{h,m,swift}"
s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.1' }

end
