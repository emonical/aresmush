module AresMUSH
  class WebApp
    post '/combat/:id/update', :auth => :approved do |id|
      @combat = Combat[id]
      if (@combat.organizer != @user && !is_admin?)
        flash[:error] = "Only the combat organizer can setup combat."
        redirect "/combat/#{id}"
      end

      errors = []
      
      @combat.active_combatants.each do |c|
        team = @params["#{c.id}-team"].to_i
        stance = @params["#{c.id}-stance"]
        weapon = @params["#{c.id}-weapon"]
        selected_weapon_specials = @params["#{c.id}-weaponspec"] || []
        selected_armor_specials = @params["#{c.id}-armorspec"] || []
        armor = @params["#{c.id}-armor"]
        armor = armor == "None" ? '' : armor
        npc = @params["#{c.id}-npc"]

        if (team != c.team)
          c.update(team: team)
          FS3Combat.emit_to_combat @combat, "#{c.name} is now on Team #{team}. (by #{@user.name})"
        end
        
        if (stance != c.stance)
          c.update(stance: stance)
          FS3Combat.emit_to_combat @combat, "#{c.name} has changed stance to #{stance}. (by #{@user.name})"
        end
        
        allowed_specials = FS3Combat.weapon_stat(weapon, "allowed_specials") || []
        weapon_specials = []
        selected_weapon_specials.each do |w|
          if (!allowed_specials.include?(w))
            errors << "#{w} is not an allowed special for #{c.name}'s #{weapon}."
          else
            weapon_specials << w
          end
        end

        if (c.weapon_name != weapon || c.weapon_specials != weapon_specials)
          FS3Combat.set_weapon(@user, c, weapon, weapon_specials)
        end
        
        allowed_specials = FS3Combat.armor_stat(armor, "allowed_specials") || []
        armor_specials = []
        selected_armor_specials.each do |a|
          if (!allowed_specials.include?(a))
            errors << "#{a} is not an allowed special for #{c.name}'s #{armor}."
          else
            armor_specials << a
          end
        end
        
        if (armor != c.armor || c.armor_specials != armor_specials)
          FS3Combat.set_armor(@user, c, armor, armor_specials)
        end
        
        if (c.is_npc? && c.npc.level != npc)
          c.npc.update(level: npc)
        end

      end
      
      if (errors.any?)
        flash[:error] = "Combat updaed, but there were some problems:<br/>- #{errors.join("<br/>- ")}"
      else
        flash[:info] = "Combat updated."
      end
      redirect "/combat/#{id}/manage"
    end
    
  end
end
