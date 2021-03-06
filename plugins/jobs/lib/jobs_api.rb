module AresMUSH
  module Jobs
        
    def self.create_job(category, title, description, author)
      if (!Jobs.categories.include?(category))
        Global.logger.debug "Invalid job category #{category}."
        return { :job => nil, :error => t('jobs.invalid_category', :categories => Jobs.categories.join(" ")) }
      end
      
      job = Job.create(:author => author, 
        :title => title, 
        :description => description, 
        :category => category,
        :number => Game.master.next_job_number,
        :status => Global.read_config("jobs", "default_status"))
        
      game = Game.master
      game.update(next_job_number: game.next_job_number + 1)
      
      message = t('jobs.announce_new_job', :number => job.number, :title => job.title, :name => author.name)
      Jobs.notify(job, message, author, false)

      return { :job => job, :error => nil }
    end
    
    def self.change_job_status(enactor, job, status, message = nil)
      if (status == Jobs.closed_status)
        status_message = t('jobs.closed_job', :name => enactor.name, :status => status)
      else
        status_message = t('jobs.changed_job_status', :name => enactor.name, :status => status)
      end
            
      message = message ? "#{message}%R%R#{status_message}" : status_message

      Jobs.comment(job, enactor, message, false)
      job.update(status: status)
    end
    
    def self.close_job(enactor, job, message = nil)
      Jobs.change_job_status(enactor, job, Jobs.closed_status, message)
    end
    
    def self.request_category
      Global.read_config("jobs", "request_category")
    end

    def self.trouble_category
      Global.read_config("jobs", "trouble_category")
    end

    def self.system_category
      Global.read_config("jobs", "system_category")
    end

  end
end