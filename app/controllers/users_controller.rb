class UsersController < ApplicationController
    def index    
        #defaut view
        @id=params[:id]
        @user = User.find_by_id(@id)
        @hashtags=@user.hashtags
        @respond_percentages = @user.percentages
        @respond_times = @respond_percentages.inject(0){|sum,x| sum + x.reply_time }
        @all_comments = @respond_percentages.inject(0){|sum,x| sum + x.total_cm }
        #level of respond persentage
        case @user.repond_percentage
        when 0..0.05
            @percentage_level = "C-"
        when 0.05..0.1
            @percentage_level = "C0"
        when 0.1..0.15
            @percentage_level = "C+"
        when 0.15..0.2
            @percentage_level = "B-"
        when 0.2..0.25
            @percentage_level = "B0"
        when 0.25..0.3
            @percentage_level = "B+"
        when 0.3..0.3333
            @percentage_level = "A-"
        when 0.3333..0.4
            @percentage_level = "A0"
        else
            @percentage_level = "A+"
        end
        if params[:percent].nil?
            @id=params[:id]
            @percentage = 16
        #view based on percentage
        else
            @percentage=params[:percent]
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
            #get score
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
        @users_all = User.all
        @users_all=@users_all.reverse
        #search
        username = params[:username]
        if !username.nil?
        @users_all = @users_all.find_all{|w| w.username.include?(username)}
        end
        #sort code
        url =  request.fullpath
        if url.include?('username')
            @urlNormal = "?utf8=✓&username=#{username}&commit=Search"
            @urlHh ="?utf8=✓&username=#{username}&commit=Search&type=hh"
            @urlHl = "?utf8=✓&username=#{username}&commit=Search&type=hl"
            @urlRh ="?utf8=✓&username=#{username}&commit=Search&type=rh"
            @urlRl = "?utf8=✓&username=#{username}&commit=Search&type=rl"
        else
            @urlNormal = "/"
            @urlHh ="?type=hh"
            @urlHl = "?type=hl"
            @urlRh ="?type=rh"
            @urlRl = "?type=rl"
        end
       #sort with drop down Average Score
       sort_type = params[:type]
       
       if (sort_type=="hh")
           @users_all=@users_all.sort_by {|u| u.score*-1}
       elsif (sort_type=="hl")
           @users_all=@users_all.sort_by {|u| u.score}
       elsif (sort_type=="rh")
            @users_all=@users_all.sort_by {|u| u.repond_percentage*-1}
       elsif (sort_type=="rl")
            @users_all=@users_all.sort_by {|u| u.repond_percentage}
       end

        # paging area
        @users=Kaminari.paginate_array(@users_all).page(params[:page]).per(10)
        
    end
    
    def create
        submitType = params[:commit]
        list_url = params[:insta_url]
        list_url = list_url.split(',')
        for url in list_url
            check = Status.find_by_username(url.delete(' '))
            if check.nil?
                Status.create(
                    username: url.delete(' '),
                    status: 'Waiting'
                )
            end
        end
        if submitType == "Add to List"
            flash[:success] = "IDs was added to list"
            redirect_to root_path
        else
            selenium_code
        end
        
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
        # kill other chrome process
        system("killall chrome")
        list_running = Status.where('status=?', 'Loading')
        for l in list_running
            l.update_attribute(:status,'Waiting')
        end
        while Status.where('status=?', 'Waiting').first.present?
            account = Status.where('status=?', 'Waiting').first
            #set status for an ID
            account.update_attribute(:status,'Loading')
            #initialize user
            @user = User.new
            #declare dom of posts
            post_dom=[]
            #declare hashtags of posts
            hashtags=[]
            #declare date 
            date=[]
            #run chrome
            options = Selenium::WebDriver::Chrome::Options.new
            options.add_argument('--headless')
            options.add_argument('--no-sandbox')
            @@bot = Selenium::WebDriver.for :chrome, options: options
            #@@bot = Selenium::WebDriver.for :chrome
            @@bot.manage.window.maximize
            sleep 1
            #go to account page
            @@bot.navigate.to "https://www.instagram.com/#{account.username}"
            sleep 1   
            if @@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div/div/div/div').size >0 
                @@bot.find_element(:xpath, '/html/body/span/section/nav/div[2]/div/div/div[3]/div/div/section/div/button').click
                #get followers
                begin
                    doc = Nokogiri::HTML(open(@@bot.current_url))
                    acc = doc.text
                    acc = acc.split('"edge_followed_by":{"count":')[1]
                    followers = (acc.split('},"followed_by_viewer"')[0]).to_i            
                end
                #get account_id
                username = @@bot.find_element(:xpath, '/html/body/span/section/main/div/header/section/div[1]/h1').text
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
                                dom=[];
                                dom[0]=i.find_element(:tag_name,'a')['href']
                                dom[1]=i.find_element(:tag_name,'img')['src']
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
                    @@bot.navigate.to "#{post_dom[i][0]}"
                    # get date of first post and date of last post
                    if i==0 ||i==post_dom.length-1 
                        date.push(@@bot.find_element(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div/a/time')['title'])
                    end
                    # pass load more comment 
                    start_time= Time.now
                    while @@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li[2]/button').size > 0 do
                        if @@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li[2]/button[@disabled=""]').size > 0
                            sleep 3
                        else
                            @@bot.find_element(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li[2]/button').click
                            sleep 0.5
                        end
                        if (Time.now > start_time + 60)
                            sleep 3 
                            if @@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li[2]/button[@disabled=""]').size > 0                    
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
                                    @@bot.navigate.to "#{post_dom[i][0]}"  
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
                                    @@bot.manage.window.maximize
                                    @@bot.navigate.to "#{post_dom[i][0]}"
                                    sleep 0.5
                                    @@bot.find_element(:xpath, '/html/body/span/section/nav/div[2]/div/div/div[3]/div/div/section/div/button').click
                                    k=0
                                    start_time= Time.now
                                end
                            else
                                start_time= Time.now
                            end
                        end
                    end
                    
                    if @@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul').size>0      
                        dom_comment=@@bot.find_element(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul')
                        #times Instagramer answer comments
                        reply_time= 0 
                        #find hashtags
                        dom_a=dom_comment.find_elements(:tag_name, 'a')
                        for d in dom_a
                            if d.text.include? "#"      
                                hashtags.push(d.text)
                            end
                            if d.text == username && d != dom_a.first
                               reply_time=reply_time+1 
                               
                            end
                        end 
                        #find percentage
                        dom_li=dom_comment=@@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li')
                        dom_li.shift   
                        total_cm = dom_li.length
                        #set percentage    
                        if dom_li.length == 0
                            percentage =0
                        else
                            percentage = reply_time.to_f/dom_li.length
                        end
                    else
                        reply_time = 0
                        total_cm = 0
                        percentage = 0
                    end 
                        @user.percentages.new(
                            link: post_dom[i][0],
                            image: post_dom[i][1],
                            reply_time: reply_time,
                            total_cm: total_cm,
                            percentage: percentage
                        )
                end
                #calculate appearance times
                appearance = hashtags.inject(Hash.new(0)) { |h,v| h[v] += 1; h }
                appearance = appearance.sort_by {|_key, value| value}
                appearance = appearance.last(20).reverse
                #Crawl used time by global
                sum =0; 
                @@bot.navigate.to "https://www.instagram.com/#{username}"
                for i in appearance
                    #pass send an emoji
                    begin
                    @@bot.find_element(:xpath, '/html/body/span/section/nav/div[2]/div/div/div[2]/input').clear
                    @@bot.find_element(:xpath, '/html/body/span/section/nav/div[2]/div/div/div[2]/input').send_keys i[0]
                    sleep 1.0
                    # wait for result or check no result found 
                    for count in 0..2
                        if @@bot.find_elements(:xpath, '/html/body/span/section/nav/div[2]/div/div/div[2]/div[2]/div[2]/div/a[1]/div/div/div[2]').size==0
                            @@bot.find_element(:xpath, '/html/body/span/section/nav/div[2]/div/div/div[2]/input').clear
                            @@bot.find_element(:xpath, '/html/body/span/section/nav/div[2]/div/div/div[2]/input').send_keys i[0]
                            sleep 1.0
                        else 
                            break
                        end
                    end
                    #hashtags -global use
                    if @@bot.find_elements(:xpath, '/html/body/span/section/nav/div[2]/div/div/div[2]/div[2]/div[2]/div/div').size > 0
                        appearance_time = 0
                    else
                        appearance_time = @@bot.find_element(:xpath, '/html/body/span/section/nav/div[2]/div/div/div[2]/div[2]/div[2]/div/a/div/div/div[2]/span/span').text
                        appearance_time =appearance_time.gsub(',','').to_i

                    end
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
                    #catach an emoji hashtag
                    rescue 
                        begin
                        @@bot.navigate.to "https://www.instagram.com/explore/tags/#{URI.encode(i[0].remove("#"))}"
                        url=URI.parse "https://www.instagram.com/explore/tags/#{URI.encode(i[0].remove("#"))}"
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
                        #avoid another http error
                        rescue OpenURI::HTTPError =>e
                            @user.hashtags.new(
                                hashtags: i[0], 
                                use_by_user:i[1],
                                use_by_global: 120,
                                avai: "null"
                                )
                        end
                    end
                end
                @@bot.quit()
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
                #remove data of existing account 
                User.find_each { |c| c.destroy if c.username==username}
                #calculate respond percentage
                total_reply_times=0
                all_cm= 0
                for post in @user.percentages
                    total_reply_times = total_reply_times + post.reply_time
                    all_cm = all_cm+post.total_cm
                end
                # avoiding divide 0
                if all_cm == 0
                    all_cm =1
                end
                respond_percentage=total_reply_times.to_f/all_cm
                #save user 
                    @user.username = username
                    @user.date_start = date[0]
                    @user.date_end =  date[1]
                    @user.followers= followers
                    @user.sum = sum
                    @user.score = score
                    @user.level = level
                    @user.repond_percentage = respond_percentage
                @user.save
                account.update_attribute(:status,'Done')
            else 
                account.update_attribute(:status,'Invalid ID')
                @@bot.quit()
            end
        end
        redirect_to status_path
    end
end
