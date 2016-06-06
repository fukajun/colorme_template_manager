require 'bundler'
Bundler.require

class TemplateSet
  def initialize(html, css)
    @css  = css
    @html = html
  end

  def save(save_root_dir, name)
    {css: @css, html: @html}.each do |ext, content|
      save_dir = "#{save_root_dir}/#{ext}"
      FileUtils.mkdir_p(save_dir)
      save_path = "#{save_dir}/#{name}.#{ext}"
      File.open(save_path, 'w+') do |file|
        file.puts(content)
      end
    end
  end
end

class ColormeCrawler

  COLORME_ADMIN_URL = 'https://admin.shop-pro.jp'

  def initialize(id, password)
    # New brwoser
    @id = id
    @password = password
    @browser = ::Watir::Browser.new phantomjs_driver
    @url = COLORME_ADMIN_URL
  end

  def backup_template(*template_nos, repositry_path: './')
    do_login
    template_nos.each do |template_no|
      do_backup(repositry_path , template_no)
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

  def do_backup(repository_path, template_no)

    save_dir = make_save_dir(repository_path, 'templates', template_no)
    (0..7).each do |template_type|
      browser.goto("#{@url}/?mode=design_tmpl_edt&smode=HTCS&tmpl_uid=#{template_no}&tmpl_type=#{template_type}")
      template_set = TemplateSet.new(browser.textarea(id:'html').value, browser.textarea(id:'css').value)
      template_set.save(save_dir, template_type)
    end

  end

  def make_save_dir(*words)
    words.join('/')
  end

  def execute_js(code)
    browser.execute_script(<<-EOS)
    var the_script = document.createElement('script');
    the_script.setAttribute('src','https://code.jquery.com/jquery-1.11.0.min.js');
    document.body.appendChild(the_script);
    EOS
    Watir::Wait.until { browser.execute_script("return !!window.jQuery") }
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

