module lut_ov5640_rgb565 #(
	parameter [11:0] HActive = 12'd800,
	parameter [11:0] VActive = 12'd600,
	parameter [12:0] HTotal  = 13'd2200,
	parameter [12:0] VTotal  = 13'd1000,
    parameter [3:0]  LUT_AW  = 4'd8,
    parameter USE_colour_bar = 1'b0,
	parameter USE_4vs3_frame = 1'b0
)(
	input       [LUT_AW-1:0] lut_index,     //Look-up table address
	output reg  [31:0]       lut_data       //Device address (8bit I2C address), register address, register data
);

wire [3:0] lut_addr_width = LUT_AW;

generate
	always@(*)
	begin
		case(lut_index)			  
		    10'd  0: lut_data <= {8'h78 , 24'h3008_02};
		    10'd  1: lut_data <= {8'h78 , 24'h3103_02};
		    10'd  2: lut_data <= {8'h78 , 24'h3017_ff};
		    10'd  3: lut_data <= {8'h78 , 24'h3018_ff};
		    10'd  4: lut_data <= {8'h78 , 24'h3037_13};
		    10'd  5: lut_data <= {8'h78 , 24'h3108_01};
		    10'd  6: lut_data <= {8'h78 , 24'h3630_36};
		    10'd  7: lut_data <= {8'h78 , 24'h3631_0e};
		    10'd  8: lut_data <= {8'h78 , 24'h3632_e2};
		    10'd  9: lut_data <= {8'h78 , 24'h3633_12};
		    10'd 10: lut_data <= {8'h78 , 24'h3621_e0};
		    10'd 11: lut_data <= {8'h78 , 24'h3704_a0};
		    10'd 12: lut_data <= {8'h78 , 24'h3703_5a};
		    10'd 13: lut_data <= {8'h78 , 24'h3715_78};
		    10'd 14: lut_data <= {8'h78 , 24'h3717_01};
		    10'd 15: lut_data <= {8'h78 , 24'h370b_60};
		    10'd 16: lut_data <= {8'h78 , 24'h3705_1a};
		    10'd 17: lut_data <= {8'h78 , 24'h3905_02};
		    10'd 18: lut_data <= {8'h78 , 24'h3906_10};
		    10'd 19: lut_data <= {8'h78 , 24'h3901_0a};
		    10'd 20: lut_data <= {8'h78 , 24'h3731_12};
		    10'd 21: lut_data <= {8'h78 , 24'h3600_08};
		    10'd 22: lut_data <= {8'h78 , 24'h3601_33};
		    10'd 23: lut_data <= {8'h78 , 24'h302d_60};
		    10'd 24: lut_data <= {8'h78 , 24'h3620_52};
		    10'd 25: lut_data <= {8'h78 , 24'h371b_20};
		    10'd 26: lut_data <= {8'h78 , 24'h471c_50};
		    10'd 27: lut_data <= {8'h78 , 24'h3a13_43};
		    10'd 28: lut_data <= {8'h78 , 24'h3a18_00};
		    10'd 29: lut_data <= {8'h78 , 24'h3a19_f8};
		    10'd 30: lut_data <= {8'h78 , 24'h3635_13};
		    10'd 31: lut_data <= {8'h78 , 24'h3636_03};
		    10'd 32: lut_data <= {8'h78 , 24'h3634_40};
		    10'd 33: lut_data <= {8'h78 , 24'h3622_01};
		    10'd 34: lut_data <= {8'h78 , 24'h3c01_34};
		    10'd 35: lut_data <= {8'h78 , 24'h3c04_28};
		    10'd 36: lut_data <= {8'h78 , 24'h3c05_98};
		    10'd 37: lut_data <= {8'h78 , 24'h3c06_00};
		    10'd 38: lut_data <= {8'h78 , 24'h3c07_07};
		    10'd 39: lut_data <= {8'h78 , 24'h3c08_00};
		    10'd 40: lut_data <= {8'h78 , 24'h3c09_1c};
			10'd 41: lut_data <= {8'h78 , 24'h3c0a_9c};
		    10'd 42: lut_data <= {8'h78 , 24'h3c0b_40};
		    10'd 43: lut_data <= {8'h78 , 24'h3810_00};
		    10'd 44: lut_data <= {8'h78 , 24'h3811_10};
		    10'd 45: lut_data <= {8'h78 , 24'h3812_00};
		    10'd 46: lut_data <= {8'h78 , 24'h3708_64};
		    10'd 47: lut_data <= {8'h78 , 24'h4001_02};
		    10'd 48: lut_data <= {8'h78 , 24'h4005_1a};
		    10'd 49: lut_data <= {8'h78 , 24'h3000_00};
		    10'd 50: lut_data <= {8'h78 , 24'h3004_ff};
		    10'd 51: lut_data <= {8'h78 , 24'h4300_61};
		    10'd 52: lut_data <= {8'h78 , 24'h501f_01};
		    10'd 53: lut_data <= {8'h78 , 24'h440e_00};
		    10'd 54: lut_data <= {8'h78 , 24'h5000_a7};
		    10'd 55: lut_data <= {8'h78 , 24'h3a0f_30};
		    10'd 56: lut_data <= {8'h78 , 24'h3a10_28};
		    10'd 57: lut_data <= {8'h78 , 24'h3a1b_30};
		    10'd 58: lut_data <= {8'h78 , 24'h3a1e_26};
		    10'd 59: lut_data <= {8'h78 , 24'h3a11_60};
		    10'd 60: lut_data <= {8'h78 , 24'h3a1f_14};
		    10'd 61: lut_data <= {8'h78 , 24'h5800_23};
		    10'd 62: lut_data <= {8'h78 , 24'h5801_14};
		    10'd 63: lut_data <= {8'h78 , 24'h5802_0f};
		    10'd 64: lut_data <= {8'h78 , 24'h5803_0f};
		    10'd 65: lut_data <= {8'h78 , 24'h5804_12};
		    10'd 66: lut_data <= {8'h78 , 24'h5805_26};
		    10'd 67: lut_data <= {8'h78 , 24'h5806_0c};
		    10'd 68: lut_data <= {8'h78 , 24'h5807_08};
		    10'd 69: lut_data <= {8'h78 , 24'h5808_05};
		    10'd 70: lut_data <= {8'h78 , 24'h5809_05};
		    10'd 71: lut_data <= {8'h78 , 24'h580a_08};
		    10'd 72: lut_data <= {8'h78 , 24'h580b_0d};
		    10'd 73: lut_data <= {8'h78 , 24'h580c_08};
		    10'd 74: lut_data <= {8'h78 , 24'h580d_03};
		    10'd 75: lut_data <= {8'h78 , 24'h580e_00};
		    10'd 76: lut_data <= {8'h78 , 24'h580f_00};
		    10'd 77: lut_data <= {8'h78 , 24'h5810_03};
		    10'd 78: lut_data <= {8'h78 , 24'h5811_09};
		    10'd 79: lut_data <= {8'h78 , 24'h5812_07};
		    10'd 80: lut_data <= {8'h78 , 24'h5813_03};
		    10'd 81: lut_data <= {8'h78 , 24'h5814_00};
		    10'd 82: lut_data <= {8'h78 , 24'h5815_01};
		    10'd 83: lut_data <= {8'h78 , 24'h5816_03};
		    10'd 84: lut_data <= {8'h78 , 24'h5817_08};
		    10'd 85: lut_data <= {8'h78 , 24'h5818_0d};
		    10'd 86: lut_data <= {8'h78 , 24'h5819_08};
		    10'd 87: lut_data <= {8'h78 , 24'h581a_05};
		    10'd 88: lut_data <= {8'h78 , 24'h581b_06};
		    10'd 89: lut_data <= {8'h78 , 24'h581c_08};
		    10'd 90: lut_data <= {8'h78 , 24'h581d_0e};
		    10'd 91: lut_data <= {8'h78 , 24'h581e_29};
		    10'd 92: lut_data <= {8'h78 , 24'h581f_17};
		    10'd 93: lut_data <= {8'h78 , 24'h5820_11};
		    10'd 94: lut_data <= {8'h78 , 24'h5821_11};
		    10'd 95: lut_data <= {8'h78 , 24'h5822_15};
		    10'd 96: lut_data <= {8'h78 , 24'h5823_28};
		    10'd 97: lut_data <= {8'h78 , 24'h5824_46};
		    10'd 98: lut_data <= {8'h78 , 24'h5825_26};
		    10'd 99: lut_data <= {8'h78 , 24'h5826_08};
		    10'd100: lut_data <= {8'h78 , 24'h5827_26};
		    10'd101: lut_data <= {8'h78 , 24'h5828_64};
		    10'd102: lut_data <= {8'h78 , 24'h5829_26};
		    10'd103: lut_data <= {8'h78 , 24'h582a_24};
		    10'd104: lut_data <= {8'h78 , 24'h582b_22};
		    10'd105: lut_data <= {8'h78 , 24'h582c_24};
		    10'd106: lut_data <= {8'h78 , 24'h582d_24};
		    10'd107: lut_data <= {8'h78 , 24'h582e_06};
		    10'd108: lut_data <= {8'h78 , 24'h582f_22};
		    10'd109: lut_data <= {8'h78 , 24'h5830_40};
		    10'd110: lut_data <= {8'h78 , 24'h5831_42};
		    10'd111: lut_data <= {8'h78 , 24'h5832_24};
		    10'd112: lut_data <= {8'h78 , 24'h5833_26};
		    10'd113: lut_data <= {8'h78 , 24'h5834_24};
		    10'd114: lut_data <= {8'h78 , 24'h5835_22};
		    10'd115: lut_data <= {8'h78 , 24'h5836_22};
		    10'd116: lut_data <= {8'h78 , 24'h5837_26};
		    10'd117: lut_data <= {8'h78 , 24'h5838_44};
		    10'd118: lut_data <= {8'h78 , 24'h5839_24};
		    10'd119: lut_data <= {8'h78 , 24'h583a_26};
		    10'd120: lut_data <= {8'h78 , 24'h583b_28};
		    10'd121: lut_data <= {8'h78 , 24'h583c_42};
		    10'd122: lut_data <= {8'h78 , 24'h583d_ce};
		    10'd123: lut_data <= {8'h78 , 24'h5180_ff};
		    10'd124: lut_data <= {8'h78 , 24'h5181_f2};
		    10'd125: lut_data <= {8'h78 , 24'h5182_00};
		    10'd126: lut_data <= {8'h78 , 24'h5183_14};
		    10'd127: lut_data <= {8'h78 , 24'h5184_25};
		    10'd128: lut_data <= {8'h78 , 24'h5185_24};
		    10'd129: lut_data <= {8'h78 , 24'h5186_09};
		    10'd130: lut_data <= {8'h78 , 24'h5187_09};
		    10'd131: lut_data <= {8'h78 , 24'h5188_09};
		    10'd132: lut_data <= {8'h78 , 24'h5189_75};
		    10'd133: lut_data <= {8'h78 , 24'h518a_54};
		    10'd134: lut_data <= {8'h78 , 24'h518b_e0};
		    10'd135: lut_data <= {8'h78 , 24'h518c_b2};
		    10'd136: lut_data <= {8'h78 , 24'h518d_42};
		    10'd137: lut_data <= {8'h78 , 24'h518e_3d};
		    10'd138: lut_data <= {8'h78 , 24'h518f_56};
		    10'd139: lut_data <= {8'h78 , 24'h5190_46};
		    10'd140: lut_data <= {8'h78 , 24'h5191_f8};
		    10'd141: lut_data <= {8'h78 , 24'h5192_04};
		    10'd142: lut_data <= {8'h78 , 24'h5193_70};
		    10'd143: lut_data <= {8'h78 , 24'h5194_f0};
		    10'd144: lut_data <= {8'h78 , 24'h5195_f0};
		    10'd145: lut_data <= {8'h78 , 24'h5196_03};
		    10'd146: lut_data <= {8'h78 , 24'h5197_01};
		    10'd147: lut_data <= {8'h78 , 24'h5198_04};
		    10'd148: lut_data <= {8'h78 , 24'h5199_12};
		    10'd149: lut_data <= {8'h78 , 24'h519a_04};
		    10'd150: lut_data <= {8'h78 , 24'h519b_00};
		    10'd151: lut_data <= {8'h78 , 24'h519c_06};
		    10'd152: lut_data <= {8'h78 , 24'h519d_82};
		    10'd153: lut_data <= {8'h78 , 24'h519e_38};
		    10'd154: lut_data <= {8'h78 , 24'h5480_01};
		    10'd155: lut_data <= {8'h78 , 24'h5481_08};
		    10'd156: lut_data <= {8'h78 , 24'h5482_14};
		    10'd157: lut_data <= {8'h78 , 24'h5483_28};
		    10'd158: lut_data <= {8'h78 , 24'h5484_51};
		    10'd159: lut_data <= {8'h78 , 24'h5485_65};
		    10'd160: lut_data <= {8'h78 , 24'h5486_71};
		    10'd161: lut_data <= {8'h78 , 24'h5487_7d};
		    10'd162: lut_data <= {8'h78 , 24'h5488_87};
		    10'd163: lut_data <= {8'h78 , 24'h5489_91};
		    10'd164: lut_data <= {8'h78 , 24'h548a_9a};
		    10'd165: lut_data <= {8'h78 , 24'h548b_aa};
		    10'd166: lut_data <= {8'h78 , 24'h548c_b8};
		    10'd167: lut_data <= {8'h78 , 24'h548d_cd};
		    10'd168: lut_data <= {8'h78 , 24'h548e_dd};
		    10'd169: lut_data <= {8'h78 , 24'h548f_ea};
		    10'd170: lut_data <= {8'h78 , 24'h5490_1d};
		    10'd171: lut_data <= {8'h78 , 24'h5381_1e};
		    10'd172: lut_data <= {8'h78 , 24'h5382_5b};
		    10'd173: lut_data <= {8'h78 , 24'h5383_08};
		    10'd174: lut_data <= {8'h78 , 24'h5384_0a};
		    10'd175: lut_data <= {8'h78 , 24'h5385_7e};
		    10'd176: lut_data <= {8'h78 , 24'h5386_88};
		    10'd177: lut_data <= {8'h78 , 24'h5387_7c};
		    10'd178: lut_data <= {8'h78 , 24'h5388_6c};
		    10'd179: lut_data <= {8'h78 , 24'h5389_10};
		    10'd180: lut_data <= {8'h78 , 24'h538a_01};
		    10'd181: lut_data <= {8'h78 , 24'h538b_98};
		    10'd182: lut_data <= {8'h78 , 24'h5580_06};
		    10'd183: lut_data <= {8'h78 , 24'h5583_40};
		    10'd184: lut_data <= {8'h78 , 24'h5584_10};
		    10'd185: lut_data <= {8'h78 , 24'h5589_10};
		    10'd186: lut_data <= {8'h78 , 24'h558a_00};
		    10'd187: lut_data <= {8'h78 , 24'h558b_f8};
		    10'd188: lut_data <= {8'h78 , 24'h501d_40};
		    10'd189: lut_data <= {8'h78 , 24'h5300_08};
		    10'd190: lut_data <= {8'h78 , 24'h5301_30};
		    10'd191: lut_data <= {8'h78 , 24'h5302_10};
		    10'd192: lut_data <= {8'h78 , 24'h5303_00};
		    10'd193: lut_data <= {8'h78 , 24'h5304_08};
		    10'd194: lut_data <= {8'h78 , 24'h5305_30};
		    10'd195: lut_data <= {8'h78 , 24'h5306_08};
		    10'd196: lut_data <= {8'h78 , 24'h5307_16};
		    10'd197: lut_data <= {8'h78 , 24'h5309_08};
		    10'd198: lut_data <= {8'h78 , 24'h530a_30};
		    10'd199: lut_data <= {8'h78 , 24'h530b_04};
		    10'd200: lut_data <= {8'h78 , 24'h530c_06};
		    10'd201: lut_data <= {8'h78 , 24'h5025_00};
			//系统时钟分频
		    10'd202: lut_data <= {8'h78 , 24'h3035_11};	//41:15fps, 21:30Fps, 11:60Fps
		    10'd203: 
				if(USE_4vs3_frame)
					 lut_data <= {8'h78 , 24'h3036_72}; //PLL倍频 , 800x600(0x5A)
				else
					 lut_data <= {8'h78 , 24'h3036_69}; //PLL倍频 , 1280x720(0x69)
		    10'd204: lut_data <= {8'h78 , 24'h3c07_08};
		    10'd205: lut_data <= {8'h78 , 24'h3820_41}; //Sensor vflip, 47=N, 41=T
		    10'd206: lut_data <= {8'h78 , 24'h3821_01}; //Sensor mirror, 01=N, 07=T
		    10'd207: lut_data <= {8'h78 , 24'h3814_31}; // timing X inc
		    10'd208: lut_data <= {8'h78 , 24'h3815_31}; // timing Y inc
		    10'd209: lut_data <= {8'h78 , 24'h3800_00};	//TIMING HS start
			10'd210: lut_data <= {8'h78 , 24'h3801_00};
		    10'd211: lut_data <= {8'h78 , 24'h3802_00};
			10'd212: 
				if(USE_4vs3_frame)
					lut_data <= {8'h78 , 24'h3803_04};	//4:3 use 04 
				else
					lut_data <= {8'h78 , 24'h3803_fa};	//4:3 use 04 
		    10'd213: lut_data <= {8'h78 , 24'h3804_0a};
		    10'd214: lut_data <= {8'h78 , 24'h3805_3f};
			10'd215:
				if(USE_4vs3_frame)
					lut_data <= {8'h78 , 24'h3806_07};	//4:3 use 07
				else
					lut_data <= {8'h78 , 24'h3806_06};	//4:3 use 07
			10'd216: 
				if(USE_4vs3_frame)
					lut_data <= {8'h78 , 24'h3807_9b}; //4:3 use 9b
				else
		    		lut_data <= {8'h78 , 24'h3807_a9}; //4:3 use 9b
		    //10'd216: lut_data <= {8'h78 , 24'h3807_a9}; //4:3 use 9b
		    10'd217: lut_data <= {8'h78 , {16'h3808, 4'd0, HActive[11:8]}};	//DVP 输出水平像素点数高4位
			10'd218: lut_data <= {8'h78 , {16'h3809, HActive[7:0]}};		//DVP 输出水平像素点数低8位
		    10'd219: lut_data <= {8'h78 , {16'h380a, 4'd0, VActive[11:8]}};	//DVP 输出垂直像素点数高3位
		    10'd220: lut_data <= {8'h78 , {16'h380b, VActive[7:0]}};		//DVP 输出垂直像素点数低8位
			10'd221: lut_data <= {8'h78 , {16'h380c, 3'd0, HTotal[12:8]}};	//水平总像素大小高5位
		    10'd222: lut_data <= {8'h78 , {16'h380d, HTotal[7:0]}};			//水平总像素大小低8位
			10'd223: lut_data <= {8'h78 , {16'h380e, 3'd0, VTotal[12:8]}};	//垂直总像素大小高5位
		    10'd224: lut_data <= {8'h78 , {16'h380f, VTotal[7:0]}};			//垂直总像素大小低8位
			10'd225: 
				if(USE_4vs3_frame)
					lut_data <= {8'h78 , 24'h3813_04};	//4:3 use 06
				else
		    		lut_data <= {8'h78 , 24'h3813_04};	//4:3 use 06
			//10'd225: lut_data <= {8'h78 , 24'h3813_04};	//4:3 use 06
		    10'd226: lut_data <= {8'h78 , 24'h3618_00};
		    10'd227: lut_data <= {8'h78 , 24'h3612_29};
		    10'd228: lut_data <= {8'h78 , 24'h3709_52};
		    10'd229: lut_data <= {8'h78 , 24'h370c_03};
		    10'd230: lut_data <= {8'h78 , 24'h3a02_17};
			10'd231: lut_data <= {8'h78 , 24'h3a03_10};
		    10'd232: lut_data <= {8'h78 , 24'h3a14_17};
		    10'd233: lut_data <= {8'h78 , 24'h3a15_10};
		    10'd234: lut_data <= {8'h78 , 24'h4004_02};
		    10'd235: lut_data <= {8'h78 , 24'h4713_03}; 
			10'd236: lut_data <= {8'h78 , 24'h4407_04};
			10'd237: lut_data <= {8'h78 , 24'h460c_20};
		    10'd238: lut_data <= {8'h78 , 24'h4837_22};
		    10'd239: lut_data <= {8'h78 , 24'h3824_02};
		    10'd240: 
				if(USE_4vs3_frame)
					lut_data <= {8'h78 , 24'h5001_a3};
				else
		    		lut_data <= {8'h78 , 24'h5001_83};
		    10'd241: lut_data <= {8'h78 , 24'h3b07_0a};
			//彩条测试使能
		    10'd242: 
                if(USE_colour_bar)
                    lut_data <= {8'h78 , 24'h503d_80}; //0x00:正常模式 0x80:彩条显示
                else
                    lut_data <= {8'h78 , 24'h503d_00};
			//闪光灯禁用
		    10'd243: lut_data <= {8'h78 , 24'h3016_00};	//Disable
		    10'd244: lut_data <= {8'h78 , 24'h301c_00};
			10'd245: lut_data <= {8'h78 , 24'h3019_00};//关闭闪光灯
			10'd246: lut_data <= {8'h78 , 24'h3031_08};//Bypass regulator
	        10'd247: lut_data <= {8'h78 , 24'h302c_C2};//output drive 4x
			10'd248: lut_data <= {8'hff , 24'hffff_ff};
			default: lut_data <= {8'h00 , 24'h0000_00};
		endcase
	end
endgenerate

endmodule 