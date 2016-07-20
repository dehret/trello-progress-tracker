require 'trello'

LANE_NAMES_TO_CONSIDER = ["Work in progress", "Feature Backlog", "Done"]
BOARD_IDS_TO_CRAWL     = ["568e1f3069112c8cedc8e194"]
TRELLO_DEV_KEY         = "65af14e…REPLACE WITH DEV KEY"
TRELLO_MEMBER_TOKEN    = "f0d68d6…REPLACE WITH MEMBER TOKEN"

Trello.configure do |config|
  config.developer_public_key = TRELLO_DEV_KEY
  config.member_token = TRELLO_MEMBER_TOKEN
end

class CardCollector
  def initialize(board_ids_to_crawl, lane_names_to_consider)
    @client = Trello::Client.new
    @boards_to_crawl = board_ids_to_crawl.map { |b| Trello::Board.find(b) }
    @lane_names_to_consider = lane_names_to_consider
  end
  
  def cards
    return @cards unless @cards.nil?
    
    cards = []
    
    @boards_to_crawl.each do |board|
      lists = board.lists
      filtered_lists = lists.select do |list|
        LANE_NAMES_TO_CONSIDER.map(&:downcase).include?(list.name.downcase)
      end
  
      filtered_lists.each do |list|
        list.cards.each do |card|
          cards << card
        end
      end
    end
    
    @cards = cards
  end
end

class AcceptanceCriteriaAggregator
  attr_reader :amount_of_acs, :amount_of_acs_checked
  
  def initialize(cards)
    @cards = cards
    aggregate_results!
  end
    
  def progress_in_percent
    (@amount_of_acs_checked.to_f / @amount_of_acs.to_f) * 100.0
  end
  
  private
    def aggregate_results!
      @amount_of_acs = @amount_of_acs_checked = 0

      @cards.each do |card|
        @amount_of_acs += card.badges['checkItems']
        @amount_of_acs_checked += card.badges['checkItemsChecked']
      end
    end  
end

collected_cards = CardCollector.new(BOARD_IDS_TO_CRAWL, LANE_NAMES_TO_CONSIDER).cards
aggregated_results = AcceptanceCriteriaAggregator.new(collected_cards)

puts "#{aggregated_results.amount_of_acs_checked} out of #{aggregated_results.amount_of_acs} ACs are checked. Progress is #{"%.02f" % aggregated_results.progress_in_percent}%"