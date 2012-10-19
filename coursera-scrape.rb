require "FileUtils"
require "watir-webdriver"

#----------------------------------------------
# Configuration (put your information here)
USERNAME = "YOUR_EMAIL_HERE"
PASSWORD = "PASSWORD"

BASE_DL_DIR = "/YOUR/DOWNLOAD/DIRECTORY/"

# Hacky way to make the browser wait for the page to load. YMMV
BROWSER_SLEEP = 4

# In class homepage: https://class.coursera.org/CLASS_URL_PATH/class/index
MY_PATH = "YOUR_CLASS_URL_PATH"
#----------------------------------------------
# Other variables (most likely don't need to be changed)

DL_DIR = BASE_DL_DIR + MY_PATH
DL_CMD = "aria2c --allow-overwrite=false --auto-file-renaming=false --check-certificate=false --load-cookies=#{DL_DIR}/cookies.txt -d #{DL_DIR} -Z"
# If you prefer wget...
#DL_CMD = "wget --content-disposition --no-check-certificate --load-cookies #{DL_DIR}/cookies.txt -P #{DL_DIR} "

# Sleep is to wait for my laggy terminal. YMMV
MAC_TERM = "osascript -e 'tell application \"Terminal\" to do script \"sleep 4; "
# Haven't tested this but should be something like this
#UNIX_TERM = "xterm -e"

SIGNIN_URL = "https://www.coursera.org/account/signin"
CLASS_URL = "https://class.coursera.org/#{MY_PATH}/lecture/index"
AUTH_URL = "https://class.coursera.org/#{MY_PATH}/auth/auth_redirector?type=login&subtype=normal"

#----------------------------------------------
def write_cookie(filename, cookie)
    data = "#{cookie[:domain]}\tFALSE\t#{cookie[:path]}" +
        "\tFALSE\t0\t#{cookie[:name]}\t#{cookie[:value]}"
    File.open(filename, 'w') {|f| f.write(data) }
end

def start_download(dl_links)
    dl_cmd = "#{DL_CMD} #{dl_links.join(" ")}"
    puts "\n\nCMD is #{dl_cmd}\"'\n\n"
    if MAC_TERM
        cmd = %Q{#{MAC_TERM}#{dl_cmd}"'} # close the single/double quotes from MAC_TERM
        system(cmd)
    end
    # Never really got to testing this part below since I only use a Mac at the
    # moment...
    #
    # elsif UNIX_TERM
    #     puts `#{UNIX_TERM} #{dl_cmd}`
    # else # Don't spawn external terminal
    #     puts `#{cmd}`
    # end
end

def main
    b = Watir::Browser.new :chrome
    b.goto SIGNIN_URL

    sleep BROWSER_SLEEP
    # Sign in
    b.text_field(:id=>"signin-email").value = USERNAME
    b.text_field(:id=>"signin-password").value = PASSWORD
    b.button(:text=>"Sign In").click

    sleep BROWSER_SLEEP
    # Authenticate class
    b.goto AUTH_URL
    sleep BROWSER_SLEEP

    # Go to lecture page
    b.goto CLASS_URL

    # Expand all
    b.links.each { |x| 
        if x.attribute_value("class") == "list_header_link contracted"; x.click end 
    }

    # Put download links to array
    dl_links = []
    b.links.each {|x| if x.href.index "download.mp4"; puts dl_links << x.href end}

    FileUtils.mkdir_p DL_DIR

    # Find cookie and write to file
    b.cookies.to_a.each { |c|
        if c[:name] == "session" and c[:domain] == "class.coursera.org" and c[:path] == "/" + MY_PATH
            write_cookie(DL_DIR + "/cookies.txt", c)
            break
        end
    }
    start_download(dl_links)
end


if __FILE__ == $0
    main
end


