module AresMUSH
  class Room
    attribute :pose_order, :type => DataType::Hash, :default => {}
    attribute :scene_set
    attribute :scene_nag, :type => DataType::Boolean, :default => true
    reference :scene, "AresMUSH::Scene"
    
    def update_pose_order(name)
      order = pose_order
      order[name] = Time.now.to_s
      update(pose_order: order)
    end
    
    def remove_from_pose_order(name)
      order = pose_order
      order.delete name
      update(pose_order: order)
    end
    
    def sorted_pose_order
      pose_order.sort_by { |name, time| Time.parse(time) }
    end
  end
  
  class Character
    attribute :pose_nospoof, :type => DataType::Boolean
    attribute :pose_autospace, :default => "%r"
    attribute :pose_quote_color
    attribute :pose_nudge, :type => DataType::Boolean, :default => true
    attribute :pose_nudge_muted, :type => DataType::Boolean
    
    def autospace
      self.pose_autospace
    end
    
    def autospace=(value)
      self.update(pose_autospace: value)
    end
    
    def last_posed
      last_pose_time = self.room.pose_order[self.name]
      return nil if !last_pose_time
      TimeFormatter.format(Time.now - Time.parse(last_pose_time))
    end
    
    def scenes_starring
      Scene.all.select { |s| s.participants.include?(self) }
    end
  end
  
  class Plot < Ohm::Model
    include ObjectModel
    
    attribute :title
    attribute :description
    attribute :summary
    
    collection :scenes, "AresMUSH::Scene"
    
    def sorted_scenes
      self.scenes.to_a.sort_by { |s| s.icdate }
    end
    
    def start_date
      first_scene = self.sorted_scenes[0]
      first_scene ? first_scene.icdate : nil
    end

    def end_date
      last_scene = self.sorted_scenes[-1]
      last_scene ? last_scene.icdate : nil
    end
  end
  
  class Scene < Ohm::Model
    include ObjectModel
    
    reference :room, "AresMUSH::Room"
    reference :owner, "AresMUSH::Character"
    attribute :date_completed, :type => DataType::Time
    attribute :date_shared, :type => DataType::Time
    
    attribute :title
    attribute :private_scene, :type => DataType::Boolean
    attribute :temp_room, :type => DataType::Boolean
    attribute :completed
    attribute :scene_type
    attribute :location
    attribute :summary
    attribute :shared
    attribute :logging_enabled, :type => DataType::Boolean, :default => true
    attribute :deletion_warned, :type => DataType::Boolean, :default => false
    attribute :icdate
    attribute :tags, :type => DataType::Array, :default => []
    
    collection :scene_poses, "AresMUSH::ScenePose"
    reference :scene_log, "AresMUSH::SceneLog"
    reference :plot, "AresMUSH::Plot"
    
    set :participants, "AresMUSH::Character"
    set :likers, "AresMUSH::Character"
    
    before_delete :delete_poses_and_log
    
    def is_private?
      self.private_scene
    end
    
    def created_date_str(char)
      OOCTime.local_short_timestr(char, self.created_at)
    end
    
    def poses_in_order
      scene_poses.to_a.sort_by { |p| p.sort_order }
    end
        
    def all_participant_names
      scene_poses.select { |s| !s.is_system_pose? }
          .map { |s| s.character.name }
          .uniq
    end
        
    def delete_poses_and_log
      scene_poses.each { |p| p.delete }
      if (self.scene_log)
        self.scene_log.delete
      end
    end
    
    def all_info_set?
      self.title && self.location && self.scene_type && self.summary
    end
    
    def date_title
      "#{self.icdate} - #{self.title}"
    end
    
    def owner_name
      self.owner ? self.owner.name : t('scenes.organizer_deleted')
    end
    
    def related_scenes
      links1 = SceneLink.find(log1_id: self.id)
      links2 = SceneLink.find(log2_id: self.id)
      list1 = links1.map { |l| l.log2 }
      list2 = links2.map { |l| l.log1 }
      list1.concat(list2).uniq
    end
    
    def participant_names
      self.participants.sort { |p| p.name }.map { |p| p.name }
    end
    
    def find_link(other_scene)
      link = SceneLink.find(log1_id: self.id).combine(log2_id: other_scene.id).first
      if (!link)
        link = SceneLink.find(log1_id: other_scene.id).combine(log2_id: self.id).first
      end
      link
    end
    
    def has_liked?(char)
      self.likers.include?(char)
    end
    
    def like(char)
      if (!self.has_liked?(char))
        self.likers.add char
      end
    end

    def unlike(char)
      if (self.has_liked?(char))
        self.likers.delete char
      end
    end
    
    def likes
      self.likers.count
    end
  end
  
  class SceneLog < Ohm::Model
    include ObjectModel
    
    attribute :log
    reference :scene, "AresMUSH::Scene"
  end
    
  class ScenePose < Ohm::Model
    include ObjectModel

    reference :character, "AresMUSH::Character"
    reference :scene, "AresMUSH::Scene"
    attribute :pose
    attribute :is_setpose, :type => DataType::Boolean
    attribute :order
    
    def sort_order
      self.order ? self.order.to_i : self.id.to_i
    end
    
    def is_setpose?
      self.is_setpose
    end
    
    def is_system_pose?
      self.character == Game.master.system_character
    end
    
    def is_gm_pose?
      self.character.is_admin? || self.character.is_playerbit?
    end
    
    def can_edit?(actor)
      return true if Scenes.can_access_scene?(actor, self.scene)
      return true if actor == self.character
      return false
    end
  end
  
  class SceneLink < Ohm::Model
    reference :log1, "AresMUSH::Scene"
    reference :log2, "AresMUSH::Scene"
    
    index :log1
    index :log2
  end
end