#ifndef  _TEST_TELOSB_UART_H
#define  _TEST_TELOSB_UART_H
enum{
  DATA_SIZE = 10, // 数据，10 bytes（含id）
  COMMOND_SIZE = 6,//命令，6byte（含id）
};

typedef nx_struct SensorMsg {
	nx_uint8_t sensorInfo[DATA_SIZE];
}SensorMsg;



enum {
  AM_SENSOR_MSG = 211,
  AM_CONTROL_MSG = 107,
};


#endif /*  _TEST_TELOSB_UART_H */
