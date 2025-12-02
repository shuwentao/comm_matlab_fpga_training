#include <stdio.h>
#include <math.h>
#include <stdlib.h>

short seg[8] = {16,32,64,128,256,512,1024,2048} ;
short slot[8] = {0,16,32,64,128,256,512,1024};
short level[8] = {1,1,2,4,8,16,32,64} ;
short datain,step,st,ss,dt;
short EncOut[256][8];
short DecOut[256];
short datarec[8];
short i,j;
short temp;
short PCM_SigIn[256]={
            0,   160,   316,   464,   601,   723,   828,   911, 
            973,  1010,  1023,  1010,   973,   911,   828,   723,
            601,   464,   316,   160,     0,  -160,  -316,  -464,
            -601,  -723,  -828,  -911,  -973, -1010, -1023, -1010,
            -973,  -911,  -828,  -723,  -601,  -464,  -316,  -160,
               0,   160,   316,   464,   601,   723,   828,   911,
             973,  1010,  1023,  1010,   973,   911,   828,   723,
             601,   464,   316,   160,     0,  -160,  -316,  -464,
            -601,  -723,  -828,  -911,  -973, -1010, -1023, -1010,
            -973,  -911,  -828,  -723,  -601,  -464,  -316,  -160,
               0,   160,   316,   464,   601,   723,   828,   911,
             973,  1010,  1023,  1010,   973,   911,   828,   723,
             601,   464,   316,   160,     0,  -160,  -316,  -464,
            -601,  -723,  -828,  -911,  -973, -1010, -1023, -1010,
            -973,  -911,  -828,  -723,  -601,  -464,  -316,  -160,
               0,   160,   316,   464,   601,   723,   828,   911,
             973,  1010,  1023,  1010,   973,   911,   828,   723,
             601,   464,   316,   160,     0,  -160,  -316,  -464,
            -601,  -723,  -828,  -911,  -973, -1010, -1023, -1010,
            -973,  -911,  -828,  -723,  -601,  -464,  -316,  -160,
               0,   160,   316,   464,   601,   723,   828,   911,
             973,  1010,  1023,  1010,   973,   911,   828,   723,
             601,   464,   316,   160,     0,  -160,  -316,  -464,
            -601,  -723,  -828,  -911,  -973, -1010, -1023, -1010,
            -973,  -911,  -828,  -723,  -601,  -464,  -316,  -160,
               0,   160,   316,   464,   601,   723,   828,   911,
             973,  1010,  1023,  1010,   973,   911,   828,   723,
             601,   464,   316,   160,     0,  -160,  -316,  -464,
            -601,  -723,  -828,  -911,  -973, -1010, -1023, -1010,
            -973,  -911,  -828,  -723,  -601,  -464,  -316,  -160,
               0,   160,   316,   464,   601,   723,   828,   911,
             973,  1010,  1023,  1010,   973,   911,   828,   723 
};


/*-----------------------------------
        Functions Declaration
-------------------------------------*/

void PCM_Encode(void);
void PCM_Decode(void);

void main()
{
    PCM_Encode();
    PCM_Decode();
    exit(0);
    do 
    {
    }while(1);
}

void PCM_Encode(void)
{
    for(i = 0 ; i < 256 ; i ++)
    {
        datain = PCM_SigIn[i];
        if(datain >= 0)
        {
            EncOut[i][0] = 0 ;
        }
        else
        {
            EncOut[i][0] = 1 ;
        }

        if((abs(datain) >= 0) && (abs(datain) < 16))
        {
            EncOut[i][1] = 0 ;
            EncOut[i][2] = 0 ;
            EncOut[i][3] = 0 ;
            step = 1 ;
            st = 0 ;
        }
        else if((abs(datain) >= 16) && (abs(datain) < 32))
        {
            EncOut[i][1] = 0 ;
            EncOut[i][2] = 0 ;
            EncOut[i][3] = 1 ;
            step = 1 ;
            st = 16 ;
        }
        else if((abs(datain) >= 32) && (abs(datain) < 64))
        {
            EncOut[i][1] = 0 ;
            EncOut[i][2] = 1 ;
            EncOut[i][3] = 0 ;
            step = 2 ;
            st = 32 ;
        }
        else if((abs(datain) >= 64) && (abs(datain) < 128))
        {
            EncOut[i][1] = 0 ;
            EncOut[i][2] = 1 ;
            EncOut[i][3] = 1 ;
            step = 4 ;
            st = 64 ;
        }
        else if((abs(datain) >= 128) && (abs(datain) < 256))
        {
            EncOut[i][1] = 1 ;
            EncOut[i][2] = 0 ;
            EncOut[i][3] = 0 ;
            step = 8 ;
            st = 128 ;
        }
        else if((abs(datain) >= 256) && (abs(datain) < 512))
        {
            EncOut[i][1] = 1 ;
            EncOut[i][2] = 0 ;
            EncOut[i][3] = 1 ;
            step = 16 ;
            st = 256 ;
        }
        else if((abs(datain) >= 512) && (abs(datain) < 1024))
        {
            EncOut[i][1] = 1 ;
            EncOut[i][2] = 1 ;
            EncOut[i][3] = 0 ;
            step = 32 ;
            st = 512 ;
        }
        else if((abs(datain) >= 1024) && (abs(datain) < 2048))
        {
            EncOut[i][1] = 1 ;
            EncOut[i][2] = 1 ;
            EncOut[i][3] = 1 ;
            step = 64 ;
            st = 1024 ;
        }
        else 
        {
            EncOut[i][1] = 1 ;
            EncOut[i][2] = 1 ;
            EncOut[i][3] = 1 ;
            step = 64 ;
            st = 1024 ;
        }

        if(abs(datain) > 2048)
        {
            for(j = 1 ; j < 7 ; j ++)
            {
                EncOut[i][j] = 1;
            }
        }

        temp = (abs(datain) - st)/step;

        EncOut[i][4] = temp >> 3;
        EncOut[i][5] = (temp - EncOut[i][4]<<3) >> 2;
        EncOut[i][6] = (temp - (EncOut[i][4]<<3) - (EncOut[i][5]<<2)) >> 1;
        EncOut[i][7] = (temp - (EncOut[i][4]<<3) - (EncOut[i][5]<<2) - (EncOut[i][6]<<1));

        //printf("%02d\n",EncOut[i][0] * 128 + EncOut[i][1] * 64 + EncOut[i][2] * 32 + EncOut[i][3] * 16 + EncOut[i][4] * 8 + EncOut[i][5] * 4 + EncOut[i][6] * 2 + EncOut[i][7] * 1);
    }
}

void PCM_Decode(void)
{
    for( i = 0 ; i < 256 ; i ++)
    {
        for( j = 0 ; j < 8 ; j ++)
        {
            datarec[j] = EncOut[i][j];
        }

        if(datarec[0] == 0)
            ss = 1;
        else
            ss = - 1;

        temp = datarec[1] * 4 + datarec[2] * 2 + datarec[3];
        st = slot[temp];
        dt = (datarec[4] * 8 + datarec[5] * 4 + datarec[6] * 2 + datarec[7]) * level[temp];
        DecOut[i] = ss * (st + dt);

        //printf("%d\n",DecOut[i]);
    }
}
