class UsersController < ApplicationController
    def index    
        id=params[:id]
        @user=User.find_by_id(id)
        @hashtags=@user.hashtags
    end
    def new
        @users = User.all
        @users=@users.reverse
        @users=Kaminari.paginate_array(@users).page(params[:page]).per(10)
    end
    
    def create
        selenium_code
    end
    def delete
        @id=params[:id]
        @user = User.find_by_id(@id)
        @user.destroy
        redirect_to root_path
    end


    ##Selenium Code
    def selenium_code
        #declare dom of posts
        post_dom=[]
        #declare hashtags of posts
        hashtags=[]
        #declare date 
        date=[]
        #Get Instagram Url
        insta_url=params[:insta_url]
        #get followers
        begin
            doc = Nokogiri::HTML(open("https://www.instagram.com/#{insta_url}"))
            acc = doc.text
            acc = acc.split('"edge_followed_by":{"count":')[1]
            followers = (acc.split('},"followed_by_viewer"')[0]).to_i            
        end
        #run chrome
        options = Selenium::WebDriver::Chrome::Options.new
        options.add_argument('--headless')
        options.add_argument('--no-sandbox')
        @@bot = Selenium::WebDriver.for :chrome, options: options
        #@@bot = Selenium::WebDriver.for :chrome
        @@bot.manage.window.maximize
        sleep 1
        #go to account page
        @@bot.navigate.to "https://www.instagram.com/#{insta_url}"
        #get account_id
        username = @@bot.find_element(:xpath, '/html/body/span/section/main/div/header/section/div[1]/h1').text
        sleep 1   
        if @@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div/div/div/div').size >0 
            @@bot.find_element(:xpath, '/html/body/span/section/nav/div[2]/div/div/div[3]/div/div/section/div/a').click
            #scroll down the account page and save dom
            for i in 0..8
                @@bot.action.send_keys(:end).perform
                sleep 1
                #save dom after 8 times press page down button
                if i%4==0
                    # elements contain the content of a post
                    dom=@@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div/div/div/div')
                    for i in dom
                        if i.find_elements(:tag_name,'a').size>0
                            dom=i.find_element(:tag_name,'a')['href']
                            post_dom.push(dom) 
                        end    
                    end      
                end 
            end
            #avoid duplicate when save dom
            post_dom=post_dom.uniq
            #Get exactly 100 post
            post_dom=post_dom[0..99]
            k=0
            for i in 0..post_dom.length-1   
                @@bot.navigate.to "#{post_dom[i]}"
                # get date of first post and date of last post
                if i==0 ||i==post_dom.length-1 
                    date.push(@@bot.find_element(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[2]/a/time')['title'])
                end
                # pass load more comment 
                start_time= Time.now
                while @@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li[2]/a[@role="button"]').size > 0 do
                    @@bot.find_element(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li[2]/a').click
                    sleep 0.5
                    if (Time.now > start_time + 60)
                        sleep 3 
                        if @@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li[2]/a[@disabled=""]').size > 0                    
                            if k==0 
                                @@bot.quit()
                                options = Selenium::WebDriver::Chrome::Options.new
                                options.add_argument('--headless')
                                options.add_argument('--no-sandbox')
                                @@bot = Selenium::WebDriver.for :chrome, options: options
                                #@@bot = Selenium::WebDriver.for :chrome
                                @@bot.manage.window.maximize
                                @@bot.navigate.to "https://www.instagram.com/accounts/login/?force_classic_login"
                                sleep 0.5
                                #using username and password to login
                                @@bot.find_element(:id, 'id_username').send_keys 'minhho402'
                                @@bot.find_element(:id, 'id_password').send_keys '515173'
                                @@bot.find_element(:class, 'button-green').click
                                sleep 0.5
                                @@bot.navigate.to "https://www.instagram.com/#{insta_url}" 
                                k=1
                                start_time= Time.now
                            else  
                                @@bot.quit()
                                options = Selenium::WebDriver::Chrome::Options.new
                                options.add_argument('--headless')
                                options.add_argument('--no-sandbox')
                                @@bot = Selenium::WebDriver.for :chrome, options: options
                                #@@bot = Selenium::WebDriver.for :chrome
                                @@bot.manage.window.maximize
                                @@bot.navigate.to "https://www.instagram.com/#{insta_url}"
                                sleep 0.5
                                @@bot.find_element(:xpath, '/html/body/span/section/nav/div[2]/div/div/div[3]/div/div/section/div/a').click
                                k=0
                                start_time= Time.now
                            end
                        else
                            start_time= Time.now
                        end
                    end
                end
                # find hashtag
                if @@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul').size>0      
                    dom=@@bot.find_element(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul')
                    dom=dom.find_elements(:tag_name, 'a')
                    for i in dom
                        if i.text.include? "#"      
                            hashtags.push(i.text.remove("#"))
                        end
                    end  
                end        
            end
            @@bot.quit()
            #remove data of existing account 
            User.find_each { |c| c.destroy if c.username==username}
            #create user 
            @user=User.new(
                username: username,
                date_start: date[0],
                date_end: date[1],
                followers: followers
                ) 
            #calculate appearance times
            appearance = hashtags.inject(Hash.new(0)) { |h,v| h[v] += 1; h }
            appearance = appearance.sort_by {|_key, value| value}
            appearance = appearance.last(20).reverse
            #Crawl used time by global
            sum =0; 
            for i in appearance
                begin
                    #@@bot.navigate.to "https://www.instagram.com/explore/tags/#{URI.encode(i[0])}"
                    url=URI.parse "https://www.instagram.com/explore/tags/#{URI.encode(i[0])}"
                    doc = Nokogiri::HTML(open(url))
                    appearance_time = doc.text
                    appearance_time = appearance_time.split('"edge_hashtag_to_media":{"count":')[1]
                    appearance_time = appearance_time.split(',"page_info":{"')[0]
                    #get availability
                    if appearance_time.to_i > 0.16*followers
                        availability = "X"
                    else
                        availability = "0"
                    end
                    #get sum 
                    if availability =="0" && appearance.index(i) < 5
                        sum = sum + i[1] * appearance_time.to_i
                    end
                    @user.hashtags.new(
                        hashtags: i[0], 
                        use_by_user:i[1],
                        use_by_global: appearance_time,
                        avai: availability
                        )
                    rescue OpenURI::HTTPError=> e
                        if e.message == '404 Not Found'   
                            appearance_time =-1
                        end
                end
            end
            #get score
            score = sum.to_f/followers
            #get level
            case score
            when 0..0.02
              level = "C-"
            when 0.02..0.06
                level = "C"
            when 0.06..0.1
                level = "C+"
            when 0.1..0.25
                level = "B-"
            when 0.25..0.5
                level = "B"
            when 0.5..1
                level = "B+"
            when 1..2
                level = "A-"
            when 2..5
                level = "A"
            else
               level = "A+"
            end
            @user.sum = sum
            @user.score = score
            @user.level = level
            @user.save
            redirect_to index_path(id: @user.id)
        else 
            flash[:danger] = "Please enter the valid username!"
            @@bot.quit()
            redirect_to root_path
        end
    end
end
