// $Id: BaseStationUartAppC.nc,v 1.0 2014-11-05 $

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


configuration BaseStationUartAppC {
}
implementation {
	components MainC, BaseStationUartC as App, LedsC;
			//AM
	components ActiveMessageC;
 	components new AMReceiverC(AM_SENSOR_MSG);
 	components new AMSenderC(AM_CONTROL_MSG);

	MainC.Boot<-App;
	App.Leds->LedsC;
	
	App.AMControl -> ActiveMessageC;
	App.AMSend -> AMSenderC;
	App.Packet -> AMSenderC;
	App.Receive -> AMReceiverC;

	// Msp430Uart0C is uart0 of MSP430F1611, pin 2 (RX) and 4 (TX) of 10 pin Expansion in telosb
	// Msp430Uart1C is uart1 of MSP430F1611, converted to USB in telosb
	//Msp430UartxC implements 3 import interfaces: Resource, UartStream, Msp430UartConfigure
	components new Msp430Uart1C() as UartC;
	App.Resource->UartC.Resource;
	App.UartStream->UartC.UartStream;
	App.Msp430UartConfigure<-UartC.Msp430UartConfigure;

}