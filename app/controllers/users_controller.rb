class UsersController < ApplicationController
    def index    
        @appearance 
        @appearance_times
        @hashtags
    end
    
    def create
        
        #declare dom of posts
        @post_dom=[]
        #declare hashtags of posts
        @hashtags=[]
        #declare times of appreance 
        @appearance_times=[] 
        #Get Instagram Url
        @insta_url=params[:insta_url]
        #run chrome
        @@bot = Selenium::WebDriver.for :chrome 
        sleep 1
        @@bot.navigate.to "#{@insta_url}"  
        sleep 1    
        @@bot.find_element(:xpath, '/html/body/span/section/nav/div[2]/div/div/div[3]/div/section/div/a').click
        #scroll down the account page and save dom
        for i in 0..8
            @@bot.action.send_keys(:end).perform
            sleep 1
            #save dom after 8 times press page down button
            if i%4==0
                # elements contain the content of a post
                dom=@@bot.find_elements(:xpath, '/html/body/span/section/main/div/article/div[1]/div/div/div')
                for i in dom
                    if i.find_elements(:tag_name,'a').size>0
                        dom=i.find_element(:tag_name,'a')['href']
                        @post_dom.push(dom) 
                    end    
                end      
            end 
        end
         #avoid duplicate when save dom
         @post_dom=@post_dom.uniq
         @a=@post_dom.length
         #Get exactly 100 post
         @post_dom=@post_dom[0..99]

         for i in 0..@post_dom.length-1   
            @@bot.navigate.to "#{@post_dom[i]}"
            @start_time= Time.now
            while @@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li[2]/a[@role="button"]').size > 0 do 
                @@bot.find_element(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li[2]/a').click
                sleep 0.7
                if Time.now > @start_time + 120
                    sleep 3
                    if @@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li[2]/a[@disabled]').size > 0 && @k==0
                     
                        @@bot.quit()
                        @@bot = Selenium::WebDriver.for :chrome 
                        @@bot.navigate.to "https://www.instagram.com/accounts/login/?force_classic_login"
                        sleep 0.5
                        #using username and password to login
                        @@bot.find_element(:id, 'id_username').send_keys 'cuong_manh248'
                        @@bot.find_element(:id, 'id_password').send_keys '24081991'
                        @@bot.find_element(:class, 'button-green').click
                        sleep 0.5
                        @@bot.navigate.to "#{@post_dom[i]}"  
                        @k=1
                        @start_time= Time.now
                    elsif @@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li[2]/a[@disabled]').size > 0 && @k==1
                        @@bot.quit()
                        @@bot = Selenium::WebDriver.for :chrome 
                        @@bot.navigate.to "#{@post_dom[i]}"
                        sleep 0.5
                        @@bot.find_element(:xpath, '/html/body/span/section/nav/div[2]/div/div/div[3]/div/section/div/a').click
                        @k=0
                        @start_time= Time.now
                    end
                end
            end
            # find hashtag
            if @@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul').size>0      
                dom=@@bot.find_element(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul')
                dom=dom.find_elements(:tag_name, 'a')
                for i in dom
                    if i.text.include? "#"      
                        @hashtags.push(i.text.remove("#"))
                    end
                end  
            end    
        end
        @@bot.quit()
        #calculate appearance times
        @appearance = @hashtags.inject(Hash.new(0)) { |h,v| h[v] += 1; h }
        @appearance = @appearance.sort_by {|_key, value| value}
        @appearance = @appearance.last(20).reverse
        #Crawl used time by global
        for i in @appearance  
            begin
                #@@bot.navigate.to "https://www.instagram.com/explore/tags/#{URI.encode(i[0])}"
                url=URI.parse "https://www.instagram.com/explore/tags/#{URI.encode(i[0])}"
                doc = Nokogiri::HTML(open(url))
                appearance_time = doc.text
                appearance_time = appearance_time.split('"edge_hashtag_to_media":{"count":')[1]
                appearance_time = appearance_time.split(',"page_info":{"')[0]
                @appearance_times.push(appearance_time)
                rescue OpenURI::HTTPError=> e
                    if e.message == '404 Not Found'   
                        @appearance_times.push('Wrong hashtags')
                    end
            end
        end
        render 'index'
    end
end
