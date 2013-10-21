require 'rake'
require 'nokogiri'
require 'open-uri'
require 'json'

EXTENSION_ID = Nokogiri::XML(File.open('install.rdf')).at('//em:id').inner_text
EXTENSION = EXTENSION_ID.gsub(/@.*/, '')
RELEASE = Nokogiri::XML(File.open('install.rdf')).at('//em:version').inner_text
SOURCES = %w{chrome resources defaults chrome.manifest install.rdf bootstrap.js}
            .collect{|f| File.directory?(f) ?  Dir["#{f}/**/*"] : f}.flatten
            .select{|f| File.file?(f)}
            .reject{|f| f =~ /[~]$/ || f =~ /\.swp$/}
            .collect{|f| f =~ /\.coffee$/i ? f.gsub(/\.coffee$/i, '.js') : f}
            .collect{|f| f =~ /\/unicode\/.xml$/ ? f.gsub(/\/unicode\.xml$/, '/unicode.js') : f }

XPI = "zotero-#{EXTENSION}-#{RELEASE}.xpi"
UNICODE = 'chrome/content/zotero-better-bibtex/unicode.js'

task :default => XPI do
end

rule '.coffee' => '.js' do |t|
  sh "coffee -c #{t.source}"
end

file XPI => SOURCES + [UNICODE] do
  Dir['*.xpi'].each{|xpi| File.unlink(xpi)}
  sh "zip -r #{XPI} #{SOURCES.collect{|f| "\"#{f}\""}.join(' ')}"
end

file 'update.rdf' => [XPI, 'install.rdf'] do
  update_rdf = Nokogiri::XML(File.open('update.rdf'))
  update_rdf.at('//em:version').content = RELEASE
  update_rdf.at('//RDF:Description')['about'] = "urn:mozilla:extension:#{EXTENSION_ID}"
  update_rdf.xpath('//em:updateLink').each{|link| link.content = "https://raw.github.com/friflaj/zotero-#{EXTENSION}/master/#{XPI}" }
  update_rdf.xpath('//em:updateInfoURL').each{|link| link.content = "https://github.com/friflaj/zotero-#{EXTENSION}" }
  File.open('update.rdf','wb') {|f| update_rdf.write_xml_to f}
end

file 'resources/translators/Better BibTex.js' => '../translators/BibTeX.js' do |t|
  cp t.prerequisites[0], t.name, :verbose => true
end

task :publish => [XPI, 'update.rdf'] do
  sh "git add --all ."
  sh "git commit -am #{RELEASE}"
  sh "git push"
end

task :release, :bump do |t, args|
  bump = args[:bump] || 'patch'

  release = RELEASE.split('.').collect{|n| Integer(n)}
  release = case bump
            when 'major' then [release[0] + 1, 0, 0]
            when 'minor' then [release[0], release[1] + 1, 0]
            when 'patch' then [release[0], release[1], release[2] + 1]
            else raise "Unexpected release increase #{bump.inspect}"
            end
  release = release.collect{|n| n.to_s}.join('.')

  install_rdf = Nokogiri::XML(File.open('install.rdf'))
  install_rdf.at('//em:version').content = release
  install_rdf.at('//em:updateURL').content = "https://raw.github.com/friflaj/zotero-#{EXTENSION}/master/update.rdf"
  File.open('install.rdf','wb') {|f| install_rdf.write_xml_to f}
  puts "Release set to #{release}. Please publish."
end

file 'chrome/content/zotero-better-bibtex/unicode.xml' do |t|
  puts "Downloading #{t.name}"
  File.open(t.name, 'wb', :encoding => 'utf-8'){|f| f.write(URI.parse('http://www.w3.org/Math/characters/unicode.xml').read) }
end

file UNICODE => ['chrome/content/zotero-better-bibtex/unicode.xml', 'Rakefile'] do |t|
  puts "Creating #{t.name}"
  mapping = Nokogiri::XML(open(t.prerequisites[0]))

  charmap = {"\u00A0" => ' '}
  mapping.xpath('//character[@id and @mode and latex]').each{|char|
    id = char['id'].to_s

    next if id =~ /^U[-0-9A-F]+$/ && id =~ /-/

    raise "Unexpected char #{id.inspect}" unless id =~ /^U[0-9A-F]+$/i

    id.gsub!(/^U/, '')
    id.gsub!(/^0/, '') if id.size == 5 && id =~ /^0/

    key = [id.gsub(/^U/i, '').hex].pack('U')
    value = char.at('.//latex').inner_text.strip

    value = "``" if value == '\\textquotedblleft'
    value = "''" if value == '\\textquotedblright'
    value = "`" if value == '\\textasciigrave'
    value = "'" if value == '\\textquotesingle'
    value = ' ' if value == "\\space"

    next if key == value

    value = "\\ensuremath{#{value}}" if char['mode'] == 'math'
    value = "{#{value}}" if value !~ /^\\/ || value !~ /}$/
    charmap[key] = value
  }
  File.open(t.name, 'wb', :encoding => 'utf-8'){|f|
    f.write("
      Zotero.BetterBibTexUnicode = {
        charmap: #{charmap.to_json},
        to_latex: function (str) {
          let res = '';
          let strlen = str.length;
          let c;
          for (let i=0; i < strlen; i++) {
            c = str.charAt(i);
            res += (this.charmap[c] || c);
          }
          return res;
        }
      };
    ")
  }
end