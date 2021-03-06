/*******************************************************************************
* File Name          : main.c
* Author             : KetilO
* Version            : V1.0.0
* Date               : 08/08/2012
* Description        : Main program body
********************************************************************************

/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"

/* Private define ------------------------------------------------------------*/
/* Private typedef -----------------------------------------------------------*/
/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
NVIC_InitTypeDef NVIC_InitStructure;
uint16_t vx;
uint16_t vy;
uint8_t pixarray[480*3/8][40]; // Should be [480*3/8][234]

/* Private function prototypes -----------------------------------------------*/
void Cls(void);
void SetPixel(uint16_t x,uint16_t y,uint8_t c);
void Rectangle(uint16_t x, uint16_t y, uint16_t b, uint16_t a, uint8_t c);
void Circle(uint16_t cx, uint16_t cy, uint16_t radius, uint8_t c);
void Line(uint16_t X1,uint16_t Y1,uint16_t X2,uint16_t Y2, uint8_t c);
void RCC_Config(void);
void NVIC_Config(void);
void GPIO_Config(void);
void TIM_Config(void);

/* Private functions ---------------------------------------------------------*/

/*******************************************************************************
* Function Name  : main
* Description    : Main program
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void main(void)
{
  asm("add  sp,#0x10000");

  RCC_Config();
  GPIO_Config();
  TIM_Config();
  NVIC_Config();
  Cls();
  SetPixel(0,0,7);
  SetPixel(1,0,7);
  SetPixel(2,0,7);
  SetPixel(3,0,7);
  SetPixel(4,0,7);
  SetPixel(5,0,7);
  SetPixel(6,0,7);
  SetPixel(7,0,7);
  SetPixel(8,0,7);
  SetPixel(9,0,7);
  while (1)
  {
  }
}

/**
  * @brief  This function clears the LCD screen.
  * @param  None
  * @retval None
  */
void Cls(void)
{
  uint16_t x;
  uint16_t y;
  y=0;
  while (y<234)
  {
    x=0;
    while (x<480*3/8)
    {
      pixarray[x][y]=0;
      x++;
    }
    y++;
  }
}

/**
  * @brief  This function sets a pixel at x, y with color c.
  * @param  x, y, c
  * @retval None
  */
void SetPixel(uint16_t x,uint16_t y,uint8_t c)
{
  uint8_t bit;
  bit=x-(x/8)*8;
  x=(x*3)/8;
  if (c && 4)
  {
    pixarray[x][y] |= bit;
  }
  else
  {
    pixarray[x][y] &= ~bit;
  }
  if (c && 2)
  {
    pixarray[x+1][y] |= bit;
  }
  else
  {
    pixarray[x+1][y] &= ~bit;
  }
  if (c && 1)
  {
    pixarray[x+2][y] |= bit;
  }
  else
  {
    pixarray[x+2][y] &= ~bit;
  }
}

/**
  * @brief  This function draw a rectangle at x, y with color c.
  * @param  x, y, b, a, c
  * @retval None
  */
void Rectangle(uint16_t x, uint16_t y, uint16_t b, uint16_t a, uint8_t c)
{
  uint16_t j;
  for (j = 0; j < a; j++) {
		SetPixel(x, y + j, c);
		SetPixel(x + b - 1, y + j, c);
	}
  for (j = 0; j < b; j++)	{
		SetPixel(x + j, y, c);
		SetPixel(x + j, y + a - 1, c);
	}
}

/**
  * @brief  This function draw a circle at x, y with color c.
  * @param  cx, cy, radius, c
  * @retval None
  */
void Circle(uint16_t cx, uint16_t cy, uint16_t radius, uint8_t c)
{
uint16_t x, y, xchange, ychange, radiusError;
x = radius;
y = 0;
xchange = 1 - 2 * radius;
ychange = 1;
radiusError = 0;
while(x >= y)
  {
  SetPixel(cx+x, cy+y, c); 
  SetPixel(cx-x, cy+y, c); 
  SetPixel(cx-x, cy-y, c);
  SetPixel(cx+x, cy-y, c); 
  SetPixel(cx+y, cy+x, c); 
  SetPixel(cx-y, cy+x, c); 
  SetPixel(cx-y, cy-x, c); 
  SetPixel(cx+y, cy-x, c); 
  y++;
  radiusError += ychange;
  ychange += 2;
  if ( 2*radiusError + xchange > 0 )
    {
    x--;
	radiusError += xchange;
	xchange += 2;
	}
  }
}

/**
  * @brief  This function draw a line from x1, y1 to x2,y2 with color c.
  * @param  x1, y1, x2, y2, c
  * @retval None
  */
void Line(uint16_t X1,uint16_t Y1,uint16_t X2,uint16_t Y2, uint8_t c)
{
uint16_t CurrentX, CurrentY, Xinc, Yinc, 
         Dx, Dy, TwoDx, TwoDy, 
         TwoDxAccumulatedError, TwoDyAccumulatedError;

Dx = (X2-X1);
Dy = (Y2-Y1);

TwoDx = Dx + Dx;
TwoDy = Dy + Dy;

CurrentX = X1;
CurrentY = Y1;

Xinc = 1;
Yinc = 1;

if(Dx < 0)
  {
  Xinc = -1;
  Dx = -Dx;
  TwoDx = -TwoDx;
  }

if (Dy < 0)
  {
  Yinc = -1;
  Dy = -Dy;
  TwoDy = -TwoDy;
  }
SetPixel(X1,Y1, c);

if ((Dx != 0) || (Dy != 0))
  {
  if (Dy <= Dx)
    { 
    TwoDxAccumulatedError = 0;
    do
	  {
      CurrentX += Xinc;
      TwoDxAccumulatedError += TwoDy;
      if(TwoDxAccumulatedError > Dx)
        {
        CurrentY += Yinc;
        TwoDxAccumulatedError -= TwoDx;
        }
       GLCD_SetPixel(CurrentX,CurrentY, c);
       }while (CurrentX != X2);
     }
   else
      {
      TwoDyAccumulatedError = 0; 
      do 
	    {
        CurrentY += Yinc; 
        TwoDyAccumulatedError += TwoDx;
        if(TwoDyAccumulatedError>Dy) 
          {
          CurrentX += Xinc;
          TwoDyAccumulatedError -= TwoDy;
          }
         GLCD_SetPixel(CurrentX,CurrentY, c);
         }while (CurrentY != Y2);
    }
  }
}

/**
  * @brief  This function enable the perperal clocks.
  * @param  None
  * @retval None
  */
void RCC_Config(void)
{
  /* Enable TIM2, GPIOA and GPIOE clocks */
  RCC_AHB1PeriphClockCmd(RCC_APB1Periph_TIM2 | RCC_AHB1Periph_GPIOA | RCC_AHB1Periph_GPIOE, ENABLE);
  /* Enable SYSCFG clock */
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_SYSCFG, ENABLE);
}

/**
  * @brief  This function enables interrupts.
  * @param  None
  * @retval None
  */
void NVIC_Config(void)
{
  /* Enable the TIM2 gloabal Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = TIM2_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 1;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
  /* Enable and set EXTI Line9_5 Interrupt to the lowest priority */
  NVIC_InitStructure.NVIC_IRQChannel = EXTI9_5_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0x01;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0x01;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
}

/**
  * @brief  This function setup the GPIO pins.
  * @param  None
  * @retval None
  */
void GPIO_Config(void)
{
  GPIO_InitTypeDef        GPIO_InitStructure;
  EXTI_InitTypeDef        EXTI_InitStructure;

  /* GPIOE Pin15 to Pin6 as outputs */
  GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_15 | GPIO_Pin_14 | GPIO_Pin_13 | GPIO_Pin_12 | GPIO_Pin_11 | GPIO_Pin_10 | GPIO_Pin_9 | GPIO_Pin_8 | GPIO_Pin_7 | GPIO_Pin_6;
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_OUT;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_NOPULL ;
  GPIO_Init(GPIOE, &GPIO_InitStructure);
  /* GPIOE Pin5 and Pin4 as input floating */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_5 | GPIO_Pin_4;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN;
  GPIO_Init(GPIOE, &GPIO_InitStructure);

  /* Connect EXTI Line4 to PE4 pin */
  SYSCFG_EXTILineConfig(EXTI_PortSourceGPIOE, EXTI_PinSource4);
  /* Configure EXTI Line4 */
  EXTI_InitStructure.EXTI_Line = EXTI_Line4;
  EXTI_InitStructure.EXTI_Mode = EXTI_Mode_Interrupt;
  EXTI_InitStructure.EXTI_Trigger = EXTI_Trigger_Rising;  
  EXTI_InitStructure.EXTI_LineCmd = ENABLE;
  EXTI_Init(&EXTI_InitStructure);

  /* Connect EXTI Line5 to PE5 pin */
  SYSCFG_EXTILineConfig(EXTI_PortSourceGPIOE, EXTI_PinSource5);
  /* Configure EXTI Line5 */
  EXTI_InitStructure.EXTI_Line = EXTI_Line5;
  EXTI_InitStructure.EXTI_Mode = EXTI_Mode_Interrupt;
  EXTI_InitStructure.EXTI_Trigger = EXTI_Trigger_Rising;  
  EXTI_InitStructure.EXTI_LineCmd = ENABLE;
  EXTI_Init(&EXTI_InitStructure);

  /* TIM2 channel 2 configuration : PA1 */
  GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_1;
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_AF;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* Connect TIM2 pin to AF1 */
  GPIO_PinAFConfig(GPIOA, GPIO_PinSource1, GPIO_AF_TIM2);
}

/**
  * @brief  This function setup TIM2.
  * @param  None
  * @retval None
  */
void TIM_Config(void)
{
  TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;

  /* TIM2 Counter configuration */
  TIM_TimeBaseStructure.TIM_Period = 0x7;
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM2, &TIM_TimeBaseStructure);
  TIM2->CCMR1 = 0x0100;     //CC2S=01
  TIM2->SMCR = 0x0067;      //TS=110, SMS=111
}

/**
  * @brief  This function handles TIM2 global interrupt request.
            The interrupt is generated for every 8 CLK pulses
            The shift registers are updated while PE6 is low
            The data latches are updated on a low to high transition on PE7
  * @param  None
  * @retval None
  */
void TIM2_IRQHandler(void)
{
  /* Set PE6 pin low, this transfers the data latches to the shift registers */
  GPIOE->BSRRH = (uint16_t)GPIO_Pin_6;
  /* Clear the IT pending Bit */
  TIM2->SR = (uint16_t)~0x1;
  /* Sets PE6 high, PE7 low and PE15 to PE8 the pixel data */
  GPIOE->ODR = (uint16_t)((pixarray[vx++][vy])<<8) | 0x7F;
  asm("nop");
  asm("nop");
  /* Set PE7 high, this transfers the pixel data to the data latches */
  GPIOE->BSRRL = (uint16_t)GPIO_Pin_7;
  asm("nop");
  asm("nop");
  /* Sets PE6 high, PE7 low and PE15 to PE8 the pixel data */
  GPIOE->ODR = (uint16_t)((pixarray[vx++][vy])<<8) | 0x7F;
  asm("nop");
  asm("nop");
  /* Set PE7 high, this transfers the pixel data to the data latches */
  GPIOE->BSRRL = (uint16_t)GPIO_Pin_7;
  asm("nop");
  asm("nop");
  /* Sets PE6 high, PE7 low and PE15 to PE8 the pixel data */
  GPIOE->ODR = (uint16_t)((pixarray[vx++][vy])<<8) | 0x7F;
  asm("nop");
  asm("nop");
  /* Set PE7 high, this transfers the pixel data to the data latches */
  GPIOE->BSRRL = (uint16_t)GPIO_Pin_7;

  if (vx = 480*3)
  {
    /* Disable the TIM2 Counter */
    TIM2->CR1 &= (uint16_t)~TIM_CR1_CEN;
  }
}

/**
  * @brief  This function handles EXTI4_IRQHandler interrupt request.
            The interrupt is generated on STHL transition
  * @param  None
  * @retval None
  */
void EXTI4_IRQHandler(void)
{
  /* Clear the EXTI line 4 pending bit */
  EXTI_ClearITPendingBit(EXTI_Line4);
  /* Increment line counter */
  vy++;
  if (vy >= 2 && vy <= 234 + 2)
  {
    /* Reset pixel byte counter */
    vx = 0;
    /* Reset TIM2 count*/
    TIM2->CNT = 0;
    /* Enable TIM2 */
    TIM2->CR1 |= TIM_CR1_CEN;
  }
  else if (vy > 234 + 2)
  {
    NVIC_InitStructure.NVIC_IRQChannelCmd = DISABLE;
    NVIC_Init(&NVIC_InitStructure);
  }
}

/**
  * @brief  This function handles EXTI9_5_IRQHandler interrupt request.
            The interrupt is generated on VSync transition
  * @param  None
  * @retval None
  */
void EXTI9_5_IRQHandler(void)
{
  /* Clear the EXTI line 5 pending bit */
  EXTI_ClearITPendingBit(EXTI_Line5);
  /* Reset line counter */
  vy = 0;
  /* Enable and set EXTI Line4 Interrupt to the lowest priority */
  NVIC_InitStructure.NVIC_IRQChannel = EXTI4_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0x01;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0x01;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
}
