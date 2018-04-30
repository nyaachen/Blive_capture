#usr/bin/sh
echo "Bilibili Live Recording shell script developed by nyaachen."
echo "Necessary Dependency: curl jq ffmpeg python(nighty)"

echo "Nighty Build 20180430"


#param1 room_id
function get_live_status()
{
    response=`curl -s "http://api.live.bilibili.com/room/v1/Room/room_init?id=$1"`
	if test $? -eq 0
	then
		status=`echo $response | jq '.data.live_status'`
	    if test $? -eq 0
		then
	        return $status
		else
			date "+[%Y-%m-%d %H:%M:%S] Server Error! These response information maybe helpful:"
			printf "$response"
		fi
	else
		date "+[%Y-%m-%d %H:%M:%S] Connection problem! Please check you internet connection."
	fi
	return -1
}

# param1 addr param2 filename
function record()
{
    ffmpeg -thread_queue_size 2048 -f live_flv -i "$1" -c copy -vsync passthrough -xerror -to 1800 -f flv "/home/nyaachen/A_Pi/record/$2"
}


# main function of this script
# Get target room

if test $1 
then
	input=$1
else
	echo "Please Enter the room_id(short_id) to continue:"
	read input
fi



# fecth for true roomid

while true
do
	response=`curl -s "http://api.live.bilibili.com/room/v1/Room/room_init?id=${1}"`
	if test $? -eq 0
	then
		true_id=`echo $response | jq '.data.room_id'`
		if test $? -eq 0
		then
			room_id=$true_id
			break
		else
			date "+[%Y-%m-%d %H:%M:%S] Server Error! These response information maybe helpful:"
			printf "$response"
			sleep 10
		fi
	else
		date "+[%Y-%m-%d %H:%M:%S] Connection Problem. Please check your Internet connection."
		sleep 10
	fi
done

# done 

date "+[%Y-%m-%d %H:%M:%S] [INFO] room_id = ${room_id}"

line=1
# fecth live status
date "+[%Y-%m-%d %H:%M:%S] [INFO] Start Monitoring now. In order to stop send SIGKILL."
while true
do
    get_live_status $room_id
    if [ $? -eq 1 ]
    then
        date "+[%Y-%m-%d %H:%M:%S] It is live time! Capture the stream now!"
        #logfile
        date "+[%Y-%m-%d %H:%M:%S] Room_id ${room_id} , Live status : Yes, Record status : Starting now" >> /home/nyaachen/A_Pi/logfile.txt
		# TODO switch from python to curl
        live_stream=`echo "${room_id}, ${line}" | python /home/nyaachen/A_Pi/get_live_stream.py`
        filename=`date "+%Y_%m_%d_%H_%M_%S_${room_id}.flv"`
        record ${live_stream} ${filename}
        response=$?
        if [ $response -eq 0 ]
        then
            time=`date "+%Y/%m/%d %H:%M:%S"`
            echo "${time} Room_id ${room_id} , Record Result: record end normally" >> /home/nyaachen/A_Pi/logfile.txt
        else
            time=`date "+%Y/%m/%d %H:%M:%S"`
            echo "${time} Room_id ${room_id} , Record Result: record end abnormally (line${line})" >> /home/nyaachen/A_Pi/logfile.txt
            #disconnect--change line
            if [ $line -eq 4 ]
            then
                line=1
            else
                let "line++"
            fi
        fi
    else
        line=1
        sleep 20
    fi
done
