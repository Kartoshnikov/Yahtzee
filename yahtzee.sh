#!/usr/bin/env bash

########################################
## Variables
########################################

pip=o
p0="         "
p1=" $pip       "
p2="    $pip    "
p3="       $pip "
p4=" $pip     $pip "
p5=" $pip  $pip  $pip "

declare -A dice scored=( [a]= [b]= [c]= [d]= [e]= [f]= [g]= [h]= [i]= [j]= [k]= [l]= [m]= )
b=$'\e[1m'
cl=$'\e[K'
fgbg='\e[3%d;4%dm'
cs=$'\e7'
cr=$'\e8'
dn=$'\e[B'
cur_put='\e[%d;%dH'
row_format='\e[3;5H%s\e[3;20H%s\e[3;35H%s\e[3;50H%s\e[3;65H%s'
indices_format='\e[9;8H%s\e[9;23H%s\e[9;38H%s\e[9;53H%s\e[9;68H%s'
score_board=\
"\e[11;19HScored Rolled"\
"\e[12;7H$cs\e[1m[a]\e[0m    Ones:%5s   %s$cl$cr$dn"\
"$cs\e[1m[b]\e[0m    Twos:%5s   %s$cl$cr$dn"\
"$cs\e[1m[c]\e[0m  Threes:%5s   %s$cl$cr$dn"\
"$cs\e[1m[d]\e[0m   Fours:%5s   %s$cl$cr$dn"\
"$cs\e[1m[e]\e[0m   Fives:%5s   %s$cl$cr$dn"\
"$cs\e[1m[f]\e[0m   Sixes:%5s   %s$cl"\
"\e[11;60HScored Rolled"\
"\e[12;41H$cs\e[1m[g]\e[0m    3 of a kind:%5s   %s$cl$cr$dn"\
"$cs\e[1m[h]\e[0m    4 of a kind:%5s   %s$cl$cr$dn"\
"$cs\e[1m[i]\e[0m     Full house:%5s   %s$cl$cr$dn"\
"$cs\e[1m[j]\e[0m Small straight:%5s   %s$cl$cr$dn"\
"$cs\e[1m[k]\e[0m Large straight:%5s   %s$cl$cr$dn"\
"$cs\e[1m[l]\e[0m        Yahtzee:%5s   %s$cl$cr$dn"\
"$cs\e[1m[m]\e[0m         Chance:%5s   %s$cl"\
"\e[19;7H[%s away from bonus]$cl\n\n\n"\
"     Upper total:%4s  Bonus:%4s  Lower total:%4s     \e[1mGrand total:%4s\e[0m$cl"
dice=(
	[1]="$b$cs$p0$cr$dn$cs$p0$cr$dn$cs$p2$cr$dn$cs$p0$cr$dn$p0"
	[2]="$b$cs$p0$cr$dn$cs$p1$cr$dn$cs$p0$cr$dn$cs$p3$cr$dn$p0"
	[3]="$b$cs$p0$cr$dn$cs$p1$cr$dn$cs$p2$cr$dn$cs$p3$cr$dn$p0"
	[4]="$b$cs$p0$cr$dn$cs$p4$cr$dn$cs$p0$cr$dn$cs$p4$cr$dn$p0"
	[5]="$b$cs$p0$cr$dn$cs$p4$cr$dn$cs$p2$cr$dn$cs$p4$cr$dn$p0"
	[6]="$b$cs$p0$cr$dn$cs$p5$cr$dn$cs$p0$cr$dn$cs$p5$cr$dn$p0"
)


########################################
###  Functions
########################################

function genarate_init_row() {
	local i rand
	
	for i in {1..5}
	do
		rand=$((RANDOM%6+1))
		row+=( $'\e[31;47m'"${dice[$rand]}"$'\e[0m' )
		row_num+=( $rand )
		indices+=( "[$i]" )
	done

	clear
}

function print_row() {
	printf "\e[1;36H\e[1m%s\e[0m" "Round ${round}"
    printf "$row_format" "${row[@]}"
   	printf "$indices_format" "${indices[@]}"

	if [[ $1 == "scored" ]]; then
		shift
		board=( "$@" )
		printf "$score_board" "${board[@]}"
	fi
}

function read_input() {
	local num=$1 sum i

	while :
	do
		if (( num == 1 ))
		then
			read -n1 -p $'\n     Which dice do you want to reroll?: ' x
			if (( $x > 0 && $x < 6 )) ; then
				break
			else
				echo " Wrong input!"
			fi
		else
			sum=0
			read -n$((num+num-1)) -p $'\n     Which dices do you want to reroll (space-separated list 1-5): 1 3 5 ?: ' -a x
			(( ${#x[@]} < $num )) && { echo "Wrong number of dices"; continue; }
			for i in ${!x[@]}; do
				if [[ " ${x[@]:$(($i+1))} " == *" ${x[$i]} "* ]]; then
					printf "%s" " Different indices are expected!"
					sum=100
					break
				fi
				(( sum+=x[i] ))
			done

			case $num in
				2) (( $sum > 9 )) && echo " Wrong input! ${x[@]}" || break
				;;
				3) (( $sum > 12 )) && echo " Wrong input! ${x[@]}" || break
				;;
				4) (( $sum > 14 )) && echo " Wrong input! ${x[@]}" || break
				;;
			esac
		fi
	done
}

function replace_dices() {
	local i x
	if [[ $1 == 5 ]]; then
		x=( {1..5} )
	else
		read_input $1
	fi
	
	for i in ${x[@]}
	do
		rand=$((RANDOM%6+1))
		row[$((i-1))]=$'\e[31;47m'"${dice[$rand]}"$'\e[0m'
		row_num[$(($i-1))]=$rand
	done
	
	print_row 
}

function merge_arr() {
	local i
	merged_arr=()
	for i in a b c d e f g h i j k l m; do 
		if [[ " ${used[@]} " == *" $i "* ]]; then
			merged_arr+=( "${scored[$i]}" " " )
		else
			merged_arr+=( "${scored[$i]}" "(${rolled[$i]:--})" )
		fi
	done

	if [ ! -z "$1" ]; then
		merged_arr+=( "$away" "$up" "$bonus" "$low" )
		if [[ $1 == 13 ]]; then
			(( grand_total = up + low + bonus ))
			merged_arr+=( $grand_total )
		fi
	fi

	print_row scored "${merged_arr[@]}"
}

function score_result() {
	declare -A rolled map
	local sorted_row_num i rolled map pair triple chance up low away bonus

	map=( [1]=a [2]=b [3]=c [4]=d [5]=e [6]=f )
	IFS=$'\n' sorted_row_num=( $(sort <<<"${row_num[*]}") ); unset IFS

	for ((i=0;i<${#sorted_row_num[@]};i++)); do
		elem=${sorted_row_num[$i]}
		map_index=${map[$elem]}
		rolled[$map_index]=$elem
		while (( elem == sorted_row_num[i+1] ));do
			(( rolled[$map_index]+=elem ))
			(( i++ ))
		done
		case $(( rolled[$map_index]/elem )) in
			2) pair=${rolled[$map_index]}
			;;
			3) 	triple=true
				rolled[g]=$(( ${sorted_row_num[@]/%/+}0 ))
			;;
			4) rolled[h]=$(( ${sorted_row_num[@]/%/+}0 ))
			   rolled[g]=${rolled[h]}
			;;
			5) rolled[l]=50
			   rolled[h]=$(( ${sorted_row_num[@]/%/+}0 ))
			   rolled[g]=${rolled[h]}   
		esac
		(( chance+=${rolled[$map_index]} ))
	done
	
	[[ $pair && $triple ]] && rolled[i]=25

	case ${sorted_row_num[@]} in
		"1 2 3 4 5"|"2 3 4 5 6") rolled[k]=40 ;;
	esac

	if [[ "${rolled[a]}" != "" \
		&& "${rolled[b]}" != "" \
		&& "${rolled[c]}" != "" \
		&& "${rolled[d]}" != "" \
	]] \
	|| [[ "${rolled[b]}" != "" \
		&& "${rolled[c]}" != "" \
		&& "${rolled[d]}" != "" \
		&& "${rolled[e]}" != "" \
	]] \
	|| [[     "${rolled[c]}" != "" \
		&& "${rolled[d]}" != "" \
		&& "${rolled[e]}" != "" \
		&& "${rolled[f]}" != "" \
	]]; then
		rolled[j]=30
	fi

	rolled[m]=$chance

	merge_arr

	while :
	do
		read -sn1 -p $'\e[25;6H\e[JSelect box to score [a-m]: ' box
		if [[ " ${used[@]} " != *" $box "* && $box =~ [a-m] ]]; then
			scored[$box]=${rolled[$box]}
			used+=( $box )
			break
		else
			echo "     Error: wrong letter"
		fi
	done

	for i in "${!scored[@]}"; do
		case $i in
			[a-f])
				(( up+=scored[$i] ))
			;;
			[g-m])
				(( low+=scored[$i] ))
			;;
		esac
	done

	(( ${away:-1} > 0 )) && away=$(( 63 - up ))
	(( ${away:-1} <= 0 )) && bonus=35
		
	replace_dices 5
	merge_arr $round
}


########################################
### Instructions and initialization
########################################

genarate_init_row


########################################
### Main loop
########################################

for round in {1..13}; do
	(( round == 1 )) && print_row scored
	for j in 0{,}; do
		while :
		do
			read -sn1 -p $'\e[25;6H\e[JHow many dices do you want to reroll (q - quit, s - skip)? ' dice_num
			case $dice_num in
				[1-5])	replace_dices $dice_num
						break
				;;
				q)	exit 0
				;;
				s)  break
				;;
			esac
		done
		[[ $dice_num == "s" ]] && break
	done
	score_result
done

printf "\e[?12l\e[?25h\e[J\n\n"

