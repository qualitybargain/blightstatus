module CasesHelper
  def update_status(step)
    puts step.inspect
    kase = step.case
    if kase
      latest = kase.most_recent_status
      if latest.nil? || step.date >= latest.date
        kase.status = step.class.to_s
        kase.save
      end
    end
  end
end
