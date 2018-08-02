class UsersController < ApplicationController
    def index    
        if params[:percent].nil?
            @id=params[:id]
            @user=User.find_by_id(@id)
            @hashtags=@user.hashtags
            @percentage = 16
        else
            @percentage=params[:percent]
            @id=params[:id]
            @user = User.find_by_id(@id)
            @hashtags=@user.hashtags
            @user.sum=0
            for i in @hashtags
                if i.use_by_global > (@percentage.to_f/100)*@user.followers
                    i.avai ="X"
                else
                    i.avai ="0"
                end
                #get sum 
                if i.avai =="0" && @hashtags.index(i) < 5
                    @user.sum = @user.sum + (i.use_by_user) * (i.use_by_global)
                end
            end
            @user.score = @user.sum.to_f/@user.followers
                #get level
                case @user.score
                when 0..0.02
                    @user.level = "C-"
                when 0.02..0.06
                    @user.level = "C"
                when 0.06..0.1
                    @user.level = "C+"
                when 0.1..0.25
                    @user.level = "B-"
                when 0.25..0.5
                    @user.level = "B"
                when 0.5..1
                    @user.level = "B+"
                when 1..2
                    @user.level = "A-"
                when 2..5
                    @user.level = "A"
                else
                    @user.level = "A+"
                end
        end
        return @user
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
        id=params[:id]
        @user = User.find_by_id(id)
        @user.destroy
        redirect_to root_path
    end

    #write excel and download
    def write_excel
        #get param
        @user = index
        @hashtags= @user.hashtags
        #generate new Excel file
        workbook = RubyXL::Workbook.new
        worksheet=workbook[0]
        #save information for all post
        worksheet.add_cell(0, 1, "ID")
        worksheet.add_cell(0, 2, "FOLLOWERS")
        worksheet.add_cell(0, 3, "LEVEL")
        worksheet.add_cell(0, 4, "SCORE")
        worksheet.add_cell(0, 5, "SUM")
        worksheet.add_cell(1, 1, @user.username)
        worksheet.add_cell(1, 2, @user.followers)
        worksheet.add_cell(1, 3, @user.level)
        worksheet.add_cell(1, 4, @user.score)
        worksheet.add_cell(1, 5, @user.sum)
        #write hashtags
        worksheet.add_cell(3, 0, "RANK")
        worksheet.add_cell(3, 1, "HASHTAG")
        worksheet.add_cell(3, 2, "TIMES")
        worksheet.add_cell(3, 3, "GLOBAL TIMES")
        worksheet.add_cell(3, 4, "VALUE")
        worksheet.add_cell(3, 5, "AVAILABILITY")
        i=0
        for hashtag in @hashtags
             worksheet.add_cell(i+4, 0, i+1)
             worksheet.add_cell(i+4, 1, hashtag.hashtags)
             worksheet.add_cell(i+4, 2, hashtag.use_by_user)
             worksheet.add_cell(i+4, 3, hashtag.use_by_global)
             worksheet.add_cell(i+4, 4, hashtag.avai == "0" ? hashtag.use_by_global*hashtag.use_by_user : 0 )
             worksheet.add_cell(i+4, 5, hashtag.avai)  
             i=i+1   
        end
            #send
            send_data( workbook.stream.string, :filename => "#{@user.username}-#{@percentage}%-hashtags.xlsx" )    
    end

    ##Selenium Code
    def selenium_code
        list_acc = ['shortbutstunning','shuni_kaeun','siyeon0220','sunmiub','suzymin','thanks_kim','theorohaejung','tingkerhee',
            'ttovely__','twinkle_sunny7','u__jee','vivamoon','vivi_saena','vvery_woony','wanna_bp','withnami','xxoziin',
            'y_aile','yejinkkk','yeonpilates','yjkang34','yoomth','yoongchic','yoonmida','you_mer']
            list_acc = list_acc.reverse
        for acc in list_acc
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
                doc = Nokogiri::HTML(open("https://www.instagram.com/#{acc}"))
                followers = doc.text
                followers = followers.split('"edge_followed_by":{"count":')[1]
                followers = (followers.split('},"followed_by_viewer"')[0]).to_i            
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
            @@bot.navigate.to "https://www.instagram.com/#{acc}"
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
                                    @@bot.navigate.to "https://www.instagram.com/#{@post_dom[i]}" 
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
                                    @@bot.navigate.to "https://www.instagram.com/#{@post_dom[i]}"
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
                #redirect_to index_path(id: @user.id)
            else 
                flash[:danger] = "Please enter the valid username!"
                @@bot.quit()
                #redirect_to root_path
            end
        end
    end
end
