require 'bundler'
Bundler.require
require 'json'

class TemplateSet
  attr_accessor :html, :css
  def initialize(html, css)
    @css  = css
    @html = html
  end

  def self.load(save_root_dir, name)
    data = {}
    {css: @css, html: @html}.keys.each do |ext|
      data[ext] = File.read(file_path(save_root_dir, name, ext))
    end
    new(data[:html], data[:css])
  end

  def save(save_root_dir, name)
    {css: @css, html: @html}.each do |ext, content|

      file_path = self.class.file_path(save_root_dir, name, ext)
      file_dir = File.dirname(file_path)
      FileUtils.mkdir_p(file_dir)
      File.open(file_path, 'w+') do |file|
        file.puts(content)
      end
    end
  end

  private
  def self.file_path(save_root_dir, name, ext)
    "#{save_root_dir}/#{ext}/#{name}.#{ext}"
  end
end

class ColormeCrawler

  COLORME_ADMIN_URL = 'https://admin.shop-pro.jp'
  TEMPLATE_NUMS = (0..7)

  def initialize(id, password)
    # New brwoser
    @id = id
    @password = password
    @browser = ::Watir::Browser.new chrome_driver
    #@browser = ::Watir::Browser.new phantomjs_driver
    @url = COLORME_ADMIN_URL
  end

  def backup_template(*template_nos, repositry_path: './')
    do_login
    template_nos.each do |template_no|
      do_backup(repositry_path , template_no)
    end
    browser.close
  end

  def restore_template(*template_nos, repositry_path: './')
    do_login
    template_nos.each do |template_no|
      do_restore(repositry_path , template_no)
    end
    browser.close
  end

  private
  def do_login
    browser.goto(@url)
    browser.text_field(name: 'login_id').set @id
    browser.text_field(name: 'password').set @password
    browser.button(:type => 'submit').click
  end

  # FIXME: htmlのみしか反映できないcssを反映できるようにしたい
  def do_restore(repository_path, template_no)
    save_dir = make_save_dir(repository_path, 'templates', template_no)
    TEMPLATE_NUMS.each do |template_type|
      template_set = TemplateSet.load(save_dir, template_type)
      browser.goto("#{@url}/?mode=design_tmpl_edt&smode=HTCS&tmpl_uid=#{template_no}&tmpl_type=#{template_type}")

      # textareaを表示する
      execute_js(<<-JS, true)
        document.getElementById("html").style.display = "block";
        //document.getElementById("css").style.display = "block";
      JS
      # JSを使用して値を入力
      sleep 1
      execute_js(<<-JS)
        var templateSet = #{({html: template_set.html, css: template_set.css}).to_json};
        $("#html").val(templateSet.html);
        //$("#css").val(templateSet.css);
      JS
      browser.textarea(id:'html').append("\n")
      #browser.textarea(id:'css').append("\n")

      # CodeMirror部分をクリックすることで更新
      browser.div(class:'CodeMirror', index: 0).click
      #browser.div(class:'CodeMirror', index: 1).click
      sleep 1

      # 更新ボタンクリック
      browser.a(id:'upper_head').click

      #
      # 再度 改行を消すために更新
      execute_js(<<-JS, true)
        document.getElementById("html").style.display = "block";
        //document.getElementById("css").style.display = "block";
      JS
      browser.textarea(id: 'html').append("\b")
      #browser.textarea(id: 'css').append("\b")
      browser.div(class:'CodeMirror', index: 0).click
      #browser.div(class:'CodeMirror', index: 1).click

      # 更新ボタンクリック
      sleep 1
      browser.a(id:'upper_head').click
    end
  end

  def do_backup(repository_path, template_no)
    save_dir = make_save_dir(repository_path, 'templates', template_no)
    TEMPLATE_NUMS.each do |template_type|
      browser.goto("#{@url}/?mode=design_tmpl_edt&smode=HTCS&tmpl_uid=#{template_no}&tmpl_type=#{template_type}")
      template_set = TemplateSet.new(browser.textarea(id:'html').value, browser.textarea(id:'css').value)
      template_set.save(save_dir, template_type)
    end
  end

  def make_save_dir(*words)
    words.join('/')
  end

  def execute_js(code, jquery_load =  false)
    if jquery_load
      browser.execute_script(<<-EOS)
      var the_script = document.createElement('script');
      the_script.setAttribute('src','https://code.jquery.com/jquery-1.11.0.min.js');
      document.body.appendChild(the_script);
      EOS
      Watir::Wait.until { browser.execute_script("return !!window.jQuery") }
    end
    browser.execute_script(code)
  end

  def browser
    @browser
  end

  def phantomjs_driver
    # Phantomjs + iphone
    capabilities = Selenium::WebDriver::Remote::Capabilities.phantomjs
    driver = Selenium::WebDriver.for(:phantomjs, :desired_capabilities => capabilities)
  end

  def chrome_driver
    # Chrome + iPhone
    driver = Webdriver::UserAgent.driver(browser: :chrome, agent: :ipad, orientation: :landscape)
  end
end

