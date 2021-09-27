module Suggestable
	extend ActiveSupport::Concern

	def name_suggestion
		"#{PositiveAdjectives.sample} #{InspirationalNouns.sample}".titleize
	end

	PositiveAdjectives =
		%w(
			admirable
			amazing
			appealing
			astonishing
			astounding
			awe-inspiring
			awesome
			beautiful
			breathtaking
			brilliant
			charming
			dazzling
			delightful
			dignified
			divine
			eager
			elegant
			enchanting
			epic
			exalted
			excellent
			exceptional
			exciting
			extraordinary
			eye-catching
			fabulous
			fantastic
			fascinating
			formidable
			glittering
			glorious
			good
			gorgeous
			grand
			great
			happy
			Heroic 
			Idyllic 
			impressive
			incredible
			inspiring
			Legendary
			lovely
			Magical
			magnificent
			majestic
			major
			marvelous
			masterly
			miraculous
			monumental
			noble
			notable
			outstanding
			perfect
			phenomenal
			picturesque
			pretty
			prodigious
			proud
			radiant
			remarkable
			respendent
			sensational
			Simple
			skillful
			solid
			sound
			spectacular
			Spellbinding 
			splendid
			staggering
			striking
			stunning
			stupendous
			sublime
			sumptuous
			super
			superb
			superior
			swanky
			terrific
			tremendous
			very\ good
			wild
			wonderful
			wondrous
		)

	InspirationalNouns =
		%w(
			accomplishment
			accord
			achievement
			actualization
			adaptation
			adventure
			affection
			agent
			agreement
			apparatus
			appliance
			arrangement
			article
			artifact
			attainment
			bargain
			basis
			biped
			birth
			campaign
			Capybara
			circuit
			circumference
			commencement
			compass
			compilation
			completion
			composition
			concurrence
			configuration
			congruity
			consistency
			consonance
			construction
			consumation
			contract
			contraption
			cosmos
			course
			covenant
			craft
			creation
			crossing
			cruise
			crystal
			crystallization
			cycle
			dawn
			design
			device
			discovery
			disposition
			effort
			embodiment
			endeavor
			engagement
			engine
			entity
			equipment
			evolution
			expedition
			experiment
			exploration
			fabrication
			fantasy
			figment
			fondness
			galaxy
			gear
			generation
			genesis
			groove
			handiwork
			harmony
			harness
			hierarchy
			idea
			image
			inauguration
			inception
			inclination
			industry
			innovation
			inspiration
			instrument
			invention
			item
			itenerary
			jaunt
			life
			machine
			masterpiece
			material
			meander
			mechanism
			mortal
			mountain
			music
			nebula
			notion
			odyssey
			opening
			orbit
			organization
			origin
			Panda
			pattern
			performance
			perimeter
			periphery
			person
			perspective
			picture
			pilgrimage
			pledge
			position
			possibility
			preface
			prelude
			presence
			presentation
			product
			production
			progress
			promise
			puzzle
			quadruped
			quest
			realization
			region
			render
			rendering
			repeair
			resonance
			resource
			river
			road
			serendipity
			sojourn
			sphere
			spring
			structure
			sunrise
			survey
			symmetry
			syncronization
			synthesis
			system
			thought
			tour
			transcript
			traversal
			trek
			turning
			undertaking
			union
			unison
			unity
			venture
			viewpoint
			visualization
			vitality
			vocation
			voyage
			widget
			winding
			Wisdom
			world
		)

end