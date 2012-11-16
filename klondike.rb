require 'securerandom'

class Klondike
	FOUNDATION_PILES = 4
	TABLEAU_PILES = 7
	@@suits = {"H" => "R",'D' => "R",'C' => "B",'S' => "B"}
	@@values = ['2','3','4','5','6','7','8','9','10','J','Q','K','A']



	def initialize
		@stock_pile = Array.new			#left over for play
		@discard_pile = Array.new		#unused stock
	 	self.new_game
	end

	def new_game
		@foundation = {"H"=> ["No Cards"], "D"=> ["No Cards"], "C"=> ["No Cards"], "S"=> ["No Cards"]}		#end result * 4 (hash of arrays)
		@tableau = {"1D" => [], "1U" => [], 
				"2D" => [], "2U" => [], 
				"3D" => [], "3U" => [], 
				"4D" => [], "4U" => [], 
				"5D" => [], "5U" => [], 
				"6D" => [], "6U" => [], 
				"7D" => [], "7U" => []}			#initial * 7 (array of arrays)
		@stock_pile.clear
		@discard_pile.clear
		@tableau_open = 0
		@foundation_open = 4
		@stock_useless = 0
		@cur_card = ""
		card_value = ""
		card_suit =  ""
		load_stock
		shuffle_deck
		deal_cards
	 	@stock_count = @stock_pile.count
	 	@cards_played = 0
	 	start
	end

	def start
		 catch (:quit) do
		 	loop do
		 		flip_card 
		 	end
		 end
	end

	def stock_finished?
		@stock_pile.count == @cards_played + @discard_pile.count || @stock_pile.count = 0
	end

	# create a stock deck
	def load_stock
		(0..3).each do |s|
			(0..12).each do |v|
				@stock_pile[@stock_pile.length] = @@values[v] + @@suits.keys[s]
			end
		end		
	end

	def shuffle_deck
		@stock_pile.shuffle!
	end


	# setup the 7 tableau piles to be played turning over the first card
	def deal_cards
		(1..7).each do |n|
			n.times do |x| 
				@tableau[n.to_s+"D"] << @stock_pile.shift
			end
			@tableau[n.to_s+"U"] << @tableau[n.to_s+"D"].pop
		end
	end

	def card_value(card)
		card.gsub(/[HDCS]/,"")
		#@card_value = @cur_card.gsub(/[HDCS]/,"")
	end
	
	def card_suit(card)
		card.gsub(/[^HDCS]/,"")
	end

	# flip a card to be played
	def flip_card
		p @cur_card
		@cur_card = @stock_pile.shift if @cur_card.empty?
		show_game
		p = self.show_opts  
		throw :quit if p == "Q"
		move_pile if p == "M"
		get_play if p == "P"
		check_stock
	end

	def move_pile
			puts "Move pile (1-7)" 
			m = gets.chomp
			puts "To pile (1-7)" 
			t = gets.chomp
			move_tableau_pile(m, t) if ok_move_pile_to_pile_for_tableau?(m, t)	
	end

	def show_opts
		puts "Current card: #{@cur_card}"
		puts "(M)ove pile or (P)lay card or (Q)uit :"
		gets.chomp.upcase
	end

	# get users play
	def get_play
		puts "Use on (F)oundaton, Pile (1-7), (D)iscard"
		i = gets.chomp.upcase
		case i
			when "F" 
				puts "(C)urrent card or (T)ableau card."
				m = gets.chomp
				move_to_foundation(m)	#foundation move
			when /[1-7]/ 
				move_to_tableau(i)	# tableau move
			when "D" 								# discard
		  		@discard_pile << @cur_card
			  	@cur_card = ""
		end
	end

	# check condition of stock pile being played
	def check_stock
		@stock_useless += 1 if @stock_count == @discard_pile.count
		if @stock_useless > 1
			p "Game is over the stock is unplayable" 
		elsif stock_finished?
			@cards_played = 0
			@stock_count = 0
			@stock_pile = @discard_pile
			@discard_pile = []
		end
	end

	# card can go to foundation pile if No Cards exists on a pile and
	# the card is an Ace or current card is the same suit and the 
	# value is higher than the last card on the pile
	def move_to_foundation(move_type)
		if move_type == "C"	#current card
			if @foundation[card_suit(@cur_card.strip)][0].eql?'No Cards' && @cur_card[0].eql?("A")
				@foundation[card_suit(@cur_card.strip)] = [@cur_card]  
				@cur_card = ""
				@cards_played += 1
			elsif card_ok_for_foundation?
				@foundation[card_suit(@cur_card.strip)] << [@cur_card]  
				@cur_card = ""
				@cards_played += 1
			else
				p "Card can't be used on the Foundation piles replay the card"
			end
		else	# use a tableau card
			puts "Which pile (1-7)? "
			p = gets.chomp
			if @foundation[card_suit(@tableau[p.to_s+"U"].last)][0].eql?'No Cards' && @tableau[p.to_s+"U"].last.eql?("A")
				@foundation[card_suit(@tableau[p.to_s+"U"].last)] = [@tableau[p.to_s+"U"].last]  
			elsif card_ok_for_foundation?
				@foundation[card_suit(@tableau[p.to_s+"U"].last)] << [@tableau[p.to_s+"U"].last]  
			else
				p "Card can't be used on the Foundation piles replay the card"
			end
		end
	end

	def check_tableau
		@tableau.each do |k,v| 
			if k.include? "U" && v.empty?
				@tableau[k] = @tableau[k[0]+"D"].last.pop
			end
	 	end
	end

	# move current card to tableau pile 
	def move_to_tableau(pile)
		if card_ok_for_tableau?(pile)
			@tableau[pile.to_s+"U"] << @cur_card
			puts @tableau
			@cur_card = ""
			@cards_played += 1
		end
	end

	# move From tableau pile to To tableau pile
	def move_tableau_pile(from, to)
			#while !@tableau[from.to_s+"U"].empty?
			@tableau[from.to_s+"U"].length.times {|x| @tableau[to.to_s+"U"] << @tableau[from.to_s+"U"].shift}
			@tableau[from.to_s+"U"] = [@tableau[from.to_s+"D"].pop]
			p @tableau
	end

	# card can be used on tableau if no cards exist or
	# the current card is a different color then that is already on the pile and
	# the current card has to be a lesser value 4 of clubs set on a 5 of hearts
  def card_ok_for_tableau?(pile)	
		@tableau[pile.to_s+"U"].empty?  ||
		 (@@values.index(card_value(@cur_card.strip)).next == ( @@values.index(card_value(@tableau[pile.to_s+"U"].last)) ) &&
		 !@@suits[card_suit(@cur_card.strip)].eql?( @@suits[card_suit(@tableau[pile.to_s+"U"].last)] ) )
#		p @tableau
	end

	# pile can be move in tableau if 
	# the from pile starts with a different color then that is already on the to pile and
	# the from pile has to be a lesser value then the to pile value ie. 4 of clubs set on a 5 of hearts
  def ok_move_pile_to_pile_for_tableau?(from, to)	
		@tableau[from.to_s+"U"].empty? && @tableau[to.to_s+"U"].empty? 
		 (@@values.index(card_value(@tableau[from.to_s+"U"].first)).next == ( @@values.index(card_value(@tableau[to.to_s+"U"].last)) ) &&
		 !@@suits[card_suit(@tableau[from.to_s+"U"].first)].eql?( @@suits[card_suit(@tableau[to.to_s+"U"].last)] ) )
#		p @tableau
	end
	# test current card against foundation pile to see if it is the same suit 
	# and the value is higher than the last card on the pile
	def card_ok_for_foundation?
		@foundation.keys.include?(card_value(card_value.strip)) &&
			@@values.index(card_value(@cur_card.strip)) > @@values.index(@foundation[card_value(@cur_card.strip)])
	end

	def show_game
		show_tableau
		show_foundation
	end

	def show_tableau
#		n = 1
		hidden = 0
		29.times {|x| print " "}
		puts "Top->Bottom cards"
		@tableau.each do |k,v| 
			if k.include? "U"
#				((n-1)*5).times {print " "}
				print "Row #{k[0]} shows: (#{hidden} turned down) #{v[0]} -> #{v[-1]}" 
				puts ""
			else
				hidden = v.count 
			end
	 	end
	end

	def show_foundation
		puts "Foundation Cards:"
		@foundation.each {|k,v| puts "    #{k} has: #{v[-1]}"}
	end

	def gameover?
		@stock_useless > 2		# two passes with same cards stop game
	end

	def tableaus_empty?
		@tableau_open > 0
	end

	def foundations_not_started?
		@foundation_open > 0
	end
end

g = Klondike.new
