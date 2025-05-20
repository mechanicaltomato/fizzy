class Command::Assign < Command
  include Command::Cards

  store_accessor :data, :assignee_ids, :toggled_assignees_by_card

  validates_presence_of :assignee_ids

  def title
    assignee_description = assignees.collect(&:first_name).join(", ")

    "Assign #{cards_description} to #{assignee_description}"
  end

  def execute
    toggled_assignees_by_card = {}

    transaction do
      cards.find_each do |card|
        toggled_assignees_by_card[card.id] = []
        assignees.find_each do |assignee|
          assign(assignee, card, toggled_assignees_by_card)
        end
      end

      update! toggled_assignees_by_card: toggled_assignees_by_card
    end
  end

  def undo
    transaction do
      toggled_assignees_by_card.each do |card_id, assignee_ids|
        card = user.accessible_cards.find_by_id(card_id)
        assignees = User.where(id: assignee_ids)

        undo_assignment(assignees, card)
      end
    end
  end

  private
    def assignees
      User.where(id: assignee_ids)
    end

    def assign(assignee, card, toggled_assignees_by_card)
      unless card.assigned_to?(assignee)
        toggled_assignees_by_card[card.id] << assignee.id
        card.toggle_assignment(assignee)
      end
    end

    def undo_assignment(assignees, card)
      if card && assignees.any?
        assignees.each do |assignee|
          card.toggle_assignment(assignee) if card.assigned_to?(assignee)
        end
      end
    end
end
