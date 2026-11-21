#!/usr/bin/env ruby
# iOS ana ekran widget hedefini (ios/ErdekWidget) Xcode projesine ekler.
# Mac/Xcode olmadan: CI'da (macOS runner) `ruby scripts/add_widget_target.rb`.
# Tekrar çalıştırılabilir: hedef zaten varsa hiçbir şey yapmaz.
# Gereken gem: xcodeproj (CocoaPods ile birlikte gelir).
require 'xcodeproj'

PROJECT = File.expand_path('../ios/Runner.xcodeproj', __dir__)
NAME = 'ErdekWidget'

project = Xcodeproj::Project.open(PROJECT)
if project.targets.any? { |t| t.name == NAME }
  puts "#{NAME} hedefi zaten var."
  exit 0
end

app = project.targets.find { |t| t.name == 'Runner' } or abort('Runner hedefi bulunamadı')
app_id = app.build_configurations.first.build_settings['PRODUCT_BUNDLE_IDENTIFIER']
family = app.build_configurations.first.build_settings['TARGETED_DEVICE_FAMILY'] || '1,2'

widget = project.new_target(:app_extension, NAME, :ios, '16.0', nil, :swift)

group = project.main_group.find_subpath(NAME, true)
group.set_source_tree('<group>')
group.set_path(NAME)
swift = group.new_reference('ErdekWidget.swift')
widget.add_file_references([swift])
group.new_reference('Info.plist')
group.new_reference('ErdekWidget.entitlements')
xcconfig = group.new_reference('Widget.xcconfig')

widget.build_configurations.each do |config|
  config.base_configuration_reference = xcconfig
  s = config.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = "#{app_id}.widget"
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['INFOPLIST_FILE'] = "#{NAME}/Info.plist"
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['CODE_SIGN_ENTITLEMENTS'] = "#{NAME}/ErdekWidget.entitlements"
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['SWIFT_VERSION'] = '5.0'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
  s['TARGETED_DEVICE_FAMILY'] = family
  s['SKIP_INSTALL'] = 'YES'
  s['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
end

# Uygulama widget'ı derleyip içine gömsün.
app.add_dependency(widget)
embed = app.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
build_file = embed.add_file_reference(widget.product_reference, true)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
# Flutter'ın "Thin Binary" betiğinden ÖNCE olmalı (yoksa derleme döngüsü hatası).
app.build_phases.delete(embed)
thin = app.build_phases.index { |p| p.respond_to?(:name) && p.name == 'Thin Binary' }
app.build_phases.insert(thin || app.build_phases.length, embed)

# Uygulamanın App Group yetkisi
runner_group = project.main_group['Runner']
runner_group.new_reference('Runner.entitlements') unless runner_group.files.any? { |f| f.path == 'Runner.entitlements' }
app.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

project.save
puts "#{NAME} hedefi eklendi (#{app_id}.widget)."
