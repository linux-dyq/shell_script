if [ -z "$1" ];then
read -p  "please enter the filename: " FILE
tail -f  $FILE |  egrep '([0-9]{1,3}\.){3}[0-9]{1,3}|([0-2][0-9]\:){2}[0-9]{2}\ |(POST|PUT|DELETE|HEAD|GET)\ (/[a-Z]*){1,}([^\ ]{1,})|\ [1-5][0-9]{2}\ ' --color
	else 
		tail -f  $1 |  egrep '([0-9]{1,3}\.){3}[0-9]{1,3}|([0-2][0-9]\:){2}[0-9]{2}\ |(POST|PUT|DELETE|HEAD|GET)\ (/[a-Z]*){1,}([^\ ]{1,})|\ [1-5][0-9]{2}\ ' --color
fi

