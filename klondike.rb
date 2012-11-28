# Klondike game

require 'securerandom'

class Cards
	@@suits = {"H" => "R",'D' => "R",'C' => "B",'S' => "B"}
	@@suit_spell = {"H" => "Heart",'D' => "Diamond",'C' => "Club",'S' => "Spade"}
#	@@values = ['A','2','3','4','5','6','7','8','9','10','J','Q','K']
	@@values = {'A' => 'Ace','2' => 'Two','3' => 'Three','4' => 'Four','5' => 'Five',
							 '6' => 'Six','7' => 'Seven','8' => 'Eight','9' => 'Nine','10' => 'Ten',
							 'J' => 'Jack','Q' => 'Queen','K' => 'King'}

	@@deck = Array.new			#left over for play

	attr_accessor :deck

	def new_game
		get_deck
		shuffle
	end

	# create a stock deck
	def get_deck
		(0..3).each do |suit|
			(0..12).each do |value|
				@@deck[@@deck.length] = @@values.keys[value] + @@suits.keys[suit]
			end
		end
	end

	def shuffle
		@@deck.shuffle!
	end
end


class Klondike < Cards
	FOUNDATION_PILES = 4
	TABLEAU_PILES = 7

	def initialize
		@stock_pile = Array.new			#left over for play
		@discard_pile = Array.new		#unused stock
		@foundation = {"H"=> ["No Cards"], "D"=> ["No Cards"], "C"=> ["No Cards"], "S"=> ["No Cards"]}		#end result * 4 (hash of arrays)
		@tableau = {"1D" => [], "1U" => [], 
				"2D" => [], "2U" => [], 
				"3D" => [], "3U" => [], 
				"4D" => [], "4U" => [], 
				"5D" => [], "5U" => [], 
				"6D" => [], "6U" => [], 
				"7D" => [], "7U" => []}			#initial * 7 (array of arrays)
		@tableau_open = 0
		@foundation_open = 4
		@stock_useless = 0
		@cur_card = ""
		card_value = ""
		card_suit =  ""
	 	@cards_played = 0
	end

	def new_game
		@stock_pile = super()		# create shuffled cards
		deal_cards							# setup cards
	 	@stock_count = @stock_pile.count  
	 	start 									# start game
	end

	# play game
	def start
		 catch (:quit) do
		 	loop do
		 		flip_card 				# get new card
				show_tableau			# show tableau cards
				show_foundation		# show foundation cards
				play_game					# play game
				reset_stock if stock_finished?				# test deck stock condition
			end
		 end
		puts "Game over try again!"
	end

	# setup the 7 tableau piles to be played turning over the first card
	def deal_cards
		(1..TABLEAU_PILES).each do |n|
			n.times do |x| 
				@tableau[n.to_s+"D"] << @stock_pile.shift
			end
			@tableau[n.to_s+"U"] << @tableau[n.to_s+"D"].pop 	# flip top card
		end
	end

	def stock_finished?
		(@stock_pile.count == @cards_played + @discard_pile.count) || @stock_pile.count == 0
	end

	def reset_stock
	  @stock_useless += 1 if @stock_count = @discard_pile.count
		@cards_played = 0
		@stock_pile = @discard_pile
	 	@stock_count = @stock_pile.count  
		@discard_pile = []
		puts "  *Discard pile is full lets replay the them* - There are #{@stock_count} cards left"
	end


	# get cards type A,K,Q etc
	def card_type(card)
		card.gsub(/[HDCS]/,"")
	end
	
	# get cards value
	def card_value(card)
		@@values.keys.index(card.gsub(/[HDCS]/,""))
	end
	
	# get card suit
	def card_suit(card)
		card.gsub(/[^HDCS]/,"")
	end

	# get card suits color
	def card_suit_color(card)
		@@suits[card.gsub(/[^HDCS]/,"")]
	end

	# flip a card to be played
	def flip_card
		@cur_card = @stock_pile.shift if @cur_card.empty?		# get new card from deck
	end

	# try to move a tableau to another tableau  pile
	def move_pile
			puts "Move pile (1-7)" 
			m = gets.chomp.slice(0)
			puts "To pile (1-7)" 
			t = gets.chomp.slice(0)
			if ok_move_pile_to_pile_for_tableau?(m, t)	
				move_tableau_pile(m, t) 
				puts "Pile moved"
			else
				puts "Piles don't match up"
			end
	end

	# get users play
	def get_card_play
		print "Use on (F)oundaton or Pile (1-7) ->"	# main play
		gets.chomp.upcase.slice(0)
	end

	# get users play on discard
	def get_discard_play
		print "Use on Pile (1-7) ->"	# main play
		gets.chomp.upcase.slice(0)
	end

	# show game information
	def play_game
		choice = get_players_move
		if choice == "Q" || gameover?
			throw :quit 
		elsif choice == "M" 	#Move a pile
			move_pile 				
		elsif choice == "U" && card_type(@discard_pile.last) == 'K'	#Move discard (King) to tableau
			discard_play = get_discard_play 
	  	move_to_tableau(@discard_pile.last, discard_play)	if card_ok_for_tableau?(@discard_pile.last, discard_play) # tableau move
		elsif choice == "D" 	#Discard
	  	@discard_pile << @cur_card
		  @cur_card = ""
		elsif choice == "P" 	#Make a Play	
			play = get_card_play	
			if play == "F" 
				print "(C)urrent card or (T)ableau card ->"
				m = gets.upcase.chomp
				move_curcard_to_foundation	if m == "C" 	# current card to foundation 
				move_tableau_to_foundation	if m == "T" 	# a tableau card to foundation 
			elsif (1..7).include?(play.to_i)
				if card_ok_for_tableau?(@cur_card, play) # tableau move
					move_to_tableau(@cur_card, play)	
					set_card_was_played
				end
			else
				puts "Invalid option"
			end
		else
			puts "Invalid option"
		end
	end

	def get_players_move
		puts "Current card: #{@cur_card}   Discard pile top card: #{@discard_pile.last}"
		if !@discard_pile.length.eql?(0) && card_type(@discard_pile.last) == 'K'
			print "(M)ove pile, (P)lay card, (U)se discard, (D)iscard or (Q)uit ->"
		else
			print "(M)ove pile, (P)lay card, (D)iscard or (Q)uit ->"
		end
		gets.chomp.upcase.slice(0)
	end

	# show all the face up tableau cards 
	def show_tableau
		hidden_cards = 0
		puts ""
		28.times {print " "}
		puts "Top -> Bottom cards"
		@tableau.each do |key, value| 
			if key.include? "U"		# Up Pile cards
				print "Row #{key[0]} shows: (#{hidden_cards} turned down) "
				if !value.count.eql?(0)
					puts "#{value[0]} -> #{value[-1]}" 
				else
					puts ""
				end
			else	# count Down pile cards in suit
				hidden_cards = value.count 	# get count for cards face down
			end
	 	end
	 	puts ""
	end

	def show_foundation
		puts "Foundation Cards:"
		@foundation.each do |k,v| 
			full_suit = @@suit_spell[k]
			if v.last.eql?('No Cards')
				puts "    #{full_suit}s has No Cards" 
			else
				result = "    #{full_suit}s top card shows a" 
				result += @@values[card_type(v.last)].eql?("Ace") ? 'n ' : ' '
				puts result << @@values[card_type(v.last)]
			end
		end
		puts ""
	end

	def gameover?
		@stock_useless > 2		# two passes with same cards stop game
	end

	# card can go to foundation pile if No Cards exists on a pile and
	# the card is an Ace or current card is the same suit and the 
	# value is higher than the last card on the pile
	def move_curcard_to_foundation
		# No cards played for a suit and current card is an Ace
		first_fndtn_card = @foundation[card_suit(@cur_card.strip)].first
		if (first_fndtn_card.eql?('No Cards') && @cur_card[0].include?("A"))	
			@foundation[card_suit(@cur_card.strip)] = [@cur_card]  
			set_card_was_played
		elsif !first_fndtn_card.eql?('No Cards') && card_ok_for_foundation(@cur_card)
			@foundation[card_suit(@cur_card.strip)] << @cur_card
			set_card_was_played
		else
			puts "Card can't be used on the Foundation piles replay the card"
		end
	end

	# card can go to foundation pile if No Cards exists on a pile and
	# the card is an Ace or current card is the same suit and the 
	# value is higher than the last card on the pile
	def move_tableau_to_foundation
		puts "Which pile (1-7)? "
		p = gets.chomp.slice(0)
		first_fndtn_card = @foundation[card_suit(@tableau[p.to_s+"U"].last)].first
		last_tableau_card = @tableau[p.to_s+"U"].last
		tableau_pile_suit = card_suit(last_tableau_card)
		if (first_fndtn_card.eql?('No Cards') && last_tableau_card.include?("A"))	# Ace
			@foundation[tableau_pile_suit] = [@tableau[p.to_s+"U"].pop]  
			check_tableau
		elsif !first_fndtn_card.eql?('No Cards') && card_ok_for_foundation(last_tableau_card)
			@foundation[tableau_pile_suit] << @tableau[p.to_s+"U"].pop
			check_tableau
		else
			puts "Card can't be used on the Foundation piles replay the card"
		end
	end

	# current card was played and must be cleared and count move
	def set_card_was_played
		@cur_card = ""
		@cards_played += 1
	end

	# check the tableau piles to flip a down card if no cards are showing
	def check_tableau
		@tableau.each do |k,v| 
#			if k.include? "U" && v.empty?
			if !k.index("U").eql?(0) && v.empty? && !@tableau[k[0]+"D"].count.eql?(0)
					@tableau[k] = [@tableau[k[0]+"D"].pop] #@tableau[k.sub("U","D")].pop 
			end
	 	end
	end

	# move current card to tableau pile 
	def move_to_tableau(card, pile)
		@tableau[pile.to_s+"U"] << card 	#@cur_card
		puts "Card moved"
	end

	# move From tableau pile to To tableau pile
	def move_tableau_pile(from, to)
			@tableau[from.to_s+"U"].length.times {|x| @tableau[to.to_s+"U"] << @tableau[from.to_s+"U"].shift}
			check_tableau
			#@tableau[from.to_s+"U"] = [@tableau[from.to_s+"D"].pop]
	end

	# card can be used on tableau if no cards exist or
	# the current card is a different color then that is already on the pile and
	# the current card has to be a lesser value 4 of clubs set on a 5 of hearts
	# OR moving a king to an empty pile
  def card_ok_for_tableau?(card, pile)	
		(@tableau[pile.to_s+"U"].count.eql?(0) && card_type(card) == 'K' ) ||
		 (card_value(card).next == ( card_value(@tableau[pile.to_s+"U"].last) ) &&
		 !card_suit_color(card).eql?( card_suit_color(@tableau[pile.to_s+"U"].last) ) )
	end

	# pile can be move in tableau if 
	# the from pile starts with a different color then that is already on the to pile and
	# the from pile has to be a lesser value then the to pile value ie. 4 of clubs set on a 5 of hearts
	# OR moving a King to a empty pile
  def ok_move_pile_to_pile_for_tableau?(from, to)	
  	tableau_from_pile = @tableau[from.to_s+"U"]
  	tableau_to_pile = @tableau[to.to_s+"U"]

		return ( !tableau_from_pile.count.eql?(0) && !tableau_to_pile.count.eql?(0) &&
						  (card_value(tableau_from_pile.first).next ==  card_value(tableau_to_pile.last))  &&
		 					!card_suit_color(tableau_from_pile.first).eql?(card_suit_color(tableau_to_pile.last)) ) ||
							( tableau_to_pile.count.eql?(0) && card_type(tableau_from_pile.first) == 'K' )
	end

	# test current card against foundation pile to see if it is the same suit 
	# and the value is higher than the last card on the pile
	def card_ok_for_foundation(card)
			card_value(card) == card_value(@foundation[card_suit(card)].last).next
	end

end

g = Klondike.new
g.new_game