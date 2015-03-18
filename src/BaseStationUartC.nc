// $Id: BaseStationUartC.nc,v 1.0 2014-11-05 $

/*
 * Copyright (c) 2014 YTC.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Uart版基站，接收AM消息，直接调用底层UART发送至串口。并以相同的方式向AM发串口接收的消息
 * @author YTC <recessburton@gmail.com>
 */


#include "BaseStationUart.h"
#include "string.h"

module BaseStationUartC {
	provides {
		interface Msp430UartConfigure;
	}
	uses {
		interface Boot;
		interface Leds;

		// Uart
		interface Resource;
		interface UartStream;

		//AM
		interface AMSend;
		interface Receive;
		interface SplitControl as AMControl;
		interface Packet;

	}
}

implementation {

	/*****************************************************************************************
	 * Global Variables
	 *****************************************************************************************/
	uint8_t capturedata[DATA_SIZE];
	uint8_t commonddata[DATA_SIZE];

	bool busy = FALSE;

	SensorMsg * btrpkg = NULL;
	message_t pkt;

	/*****************************************************************************************
	 * Task & function declaration
	 *****************************************************************************************/
	task void requestUART();
	task void releaseUART();

	/*****************************************************************************************
	 * Boot
	 *****************************************************************************************/ 

	event void Boot.booted() {
		call AMControl.start();
		call Leds.led0On();
		//call Leds.led1On();
		//call Leds.led2On();
		post requestUART();
	}

	/*****************************************************************************************
	 * Uart Configuration
	 *****************************************************************************************/ 

	msp430_uart_union_config_t msp430_uart_config = {{ ubr : UBR_1MHZ_115200, // Baud rate (use enum msp430_uart_rate_t in msp430usart.h for predefined rates)
			umctl : UMCTL_1MHZ_115200, // Modulation (use enum msp430_uart_rate_t in msp430usart.h for predefined rates)
			ssel : 0x02, // Clock source (00=UCLKI; 01=ACLK; 10=SMCLK; 11=SMCLK)
			pena : 0, // Parity enable (0=disabled; 1=enabled)
			pev : 0, // Parity select (0=odd; 1=even)
			spb : 0, // Stop bits (0=one stop bit; 1=two stop bits)
			clen : 1, // Character length (0=7-bit data; 1=8-bit data)
			listen : 0, // Listen enable (0=disabled; 1=enabled, feed tx back to receiver)
			mm : 0, // Multiprocessor mode (0=idle-line protocol; 1=address-bit protocol)
			ckpl : 0, // Clock polarity (0=normal; 1=inverted)
			urxse : 0, // Receive start-edge detection (0=disabled; 1=enabled)
			urxeie : 1, // Erroneous-character receive (0=rejected; 1=recieved and URXIFGx set)
			urxwie : 0, // Wake-up interrupt-enable (0=all characters set URXIFGx; 1=only address sets URXIFGx)
			utxe : 1, // 1:enable tx module
			urxe : 1	// 1:enable rx module      

	}};

	async command msp430_uart_union_config_t * Msp430UartConfigure.getConfig() {
		return & msp430_uart_config;
	}

	/*****************************************************************************************
	 * Uart Usage
	 *****************************************************************************************/ 

	task void requestUART() {
		call Resource.request();	// Request UART Resource
	}

	task void releaseUART() {
		call Resource.release();
	}

	event void Resource.granted() {
		call UartStream.receive(commonddata, COMMOND_SIZE);
	}

	async event void UartStream.sendDone(uint8_t * buf, uint16_t len,
			error_t error) {
		if(error == SUCCESS) {
			call Leds.led0Toggle();
			//call UartStream.receive(capturedata, DATA_SIZE); // Receive data message
		}
		else {
			//call UartStream.receive(capturedata, DATA_SIZE);
		}
	}

	async event void UartStream.receivedByte(uint8_t byte) {

	}

	async event void UartStream.receiveDone(uint8_t * buf, uint16_t len, error_t error) {
		//接收到控制命令
			error_t result;
		int8_t k;
		int16_t nodeid;
		
		memset(commonddata,DATA_SIZE,0);
		
		if(len == COMMOND_SIZE) {
			call Leds.led2Toggle();
			memcpy(commonddata, buf, COMMOND_SIZE);
 
			btrpkg = (SensorMsg * )(call Packet.getPayload(&pkt, NULL));
			for(k=0;k<6;k++){
				btrpkg->sensorInfo[k] = commonddata[k];
			}

			if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(SensorMsg)) == SUCCESS) {
				busy = TRUE;
			}

		}
		else {
			call UartStream.receive(commonddata, COMMOND_SIZE);
		}
	}

	//发送成功的话busy释放，
	event void AMSend.sendDone(message_t * msg, error_t err) {
		if(err == SUCCESS) {
			call Leds.led1Toggle();
			busy = FALSE;
			call UartStream.receive(commonddata, COMMOND_SIZE);
		}
	}

	//启动芯片
	event void AMControl.startDone(error_t err) {
		if(err == SUCCESS) {
			;
		}
		else {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err) {
	}
	
	event message_t* Receive.receive(message_t* msg, void* playload, uint8_t len) {
		int8_t k;

			for(k=0;k<10;k++){
				capturedata[k] = 0;
			}

		if(len == sizeof(SensorMsg)) 
		{
			SensorMsg* btrpkg = (SensorMsg*)playload;
			/*for(k=0;k<10;k++){
				capturedata[k] = btrpkg->sensorInfo[k];
			}*/
			memcpy(capturedata, btrpkg->sensorInfo, DATA_SIZE);
			
	/*	if( capturedata[0] != 0x55 ||  capturedata[9] != 0xaa)
			{
			 		//丢弃
					call Leds.led1Toggle();
					for(k=0;k<10;k++){
						btrpkg->sensorInfo[k] = 0;
					}
				playload = NULL;
				return msg;
			}*/
			
			call UartStream.send(capturedata, DATA_SIZE);
 
			for(k=0;k<10;k++){
				btrpkg->sensorInfo[k] = 0;
			}
			playload = NULL;
		}
		return msg;
	}

}// End 