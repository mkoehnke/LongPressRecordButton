Pod::Spec.new do |s|

  s.name         = "LongPressRecordButton"
  s.version      = "1.5.0"
  s.summary      = "Simple and easy-to-use record button for iOS, that enforces a long press, similar to Instagram"

  s.description  = <<-DESC
                   Simple and easy-to-use record button for iOS, that enforces a long press (and shows a tooltip when short-pressed) 
                   similar to the Instagram app.
                   DESC

  s.homepage     = "https://github.com/mkoehnke/LongPressRecordButton"

  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  
  s.author       = "Mathias Köhnke"
  
  s.platform     = :ios, "9.0"

  s.source       = { :git => "https://github.com/mkoehnke/LongPressRecordButton.git", :tag => s.version.to_s }

  s.source_files  = "LongPressRecordButton", "LongPressRecordButton/**/*.{swift}"
  s.exclude_files = "Classes/Exclude"
  
  s.requires_arc = true

end
