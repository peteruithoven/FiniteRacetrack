#define THROTTLE_SENSOR1 3
#define THROTTLE_SENSOR2 4
#define LED1	         9
#define LED2	         10
#define CAR1             5
#define CAR2             6

#define ENERGY_LED1	7
#define ENERGY_LED2	8
#define ENERGY_LED3	11
#define ENERGY_LED4	12

#define ENERGY_RESET    4

int trottle1 = 0;
int trottle2 = 0;

int minTrottle1 = 9999;
int maxTrottle1 = 0;
int minTrottle2 = 9999;
int maxTrottle2 = 0;

int trottleNoise = 5;

float power1 = 0;
float power2 = 0;

boolean refill = false;
//2.5(sec per round)*10(rounds)*30(fps)*80(regular power usage per car)*2(cars)*0.75(restriction) = 90000
// 52869(1 car,10 rounds)*2(cars)*0.75(restriction) = 79303; /10
unsigned int maxEnergy = 32767;
unsigned int availableEnergy = maxEnergy; 
//48000(start energy) / ( 40(duration of recovery in seconds)*30(fps) ) = 40(energy growth)
int energyGrowth = 4; //20 (demo); // 1 car uses 100 max

float startRestrictionEnergyLevel = 0.25;

unsigned long  prevMillis;
unsigned int powerCounter = 0;
int startSeconds = 0;


void setup()
{
  pinMode(CAR1, OUTPUT);
  pinMode(CAR2, OUTPUT);
  pinMode(LED1,OUTPUT);
  pinMode(LED2,OUTPUT);
  pinMode(ENERGY_LED1,OUTPUT);
  pinMode(ENERGY_LED2,OUTPUT);
  pinMode(ENERGY_LED3,OUTPUT);
  pinMode(ENERGY_LED4,OUTPUT);
  pinMode(ENERGY_RESET,OUTPUT);  
  digitalWrite(ENERGY_RESET,HIGH);
  
  Serial.begin(9600);
  
  Serial.println('r'); 
  
  delay(1000);
  
  prevMillis = millis();
}

void loop()
{
  //Serial.println(availableEnergy);
  
  trottle1 = analogRead(THROTTLE_SENSOR1);
  trottle2 = analogRead(THROTTLE_SENSOR2);
  
  if(trottle1 < minTrottle1) minTrottle1 = trottle1;
  if(trottle1 > maxTrottle1) maxTrottle1 = trottle1;
  if(trottle1-minTrottle1 < trottleNoise) trottle1 = minTrottle1;
  if(maxTrottle1-trottle1 < trottleNoise) trottle1 = maxTrottle1;
  power1 = (trottle1-minTrottle1);
  power1 = power1 / (maxTrottle1-minTrottle1) * 255;
  
  powerCounter += power1;
  
  //Serial.println(powerCounter);
  
  if(trottle2 < minTrottle2) minTrottle2 = trottle2;
  if(trottle2 > maxTrottle2) maxTrottle2 = trottle2;
  if(trottle2-minTrottle2 < trottleNoise) trottle2 = minTrottle2;
  if(maxTrottle2-trottle2 < trottleNoise) trottle2 = maxTrottle2;
  power2 = (trottle2-minTrottle2);
  power2 = power2 / (maxTrottle2-minTrottle2) * 255;
  
  /*Serial.print(trottle1);
  Serial.print(' ');
  Serial.print(minTrottle1);
  Serial.print(' ');
  Serial.print(maxTrottle1);
  Serial.print(' ');
  Serial.print((maxTrottle1-minTrottle1));
  Serial.print(' ');
  Serial.println(power1);*/
  
  //Serial.print(power1);
  //Serial.print(' ');
  //Serial.println(power2);  
  
  analogWrite(LED1, power1);
  analogWrite(LED2, power2);
  

  int energyCost1 = float(power1)/float(255)*9;
  int energyCost2 = float(power2)/float(255)*9;
  //float percOfFrame = 1; //float((millis()-prevMillis)) / (1000.0/30.0);
  //prevMillis = millis();
  //print("percOfFrame: "+percOfFrame+" ");
  //float energyCostsPerLoop = (energyCost1+energyCost2)*percOfFrame;
  int energyCosts = energyCost1+energyCost2;
  
  if(availableEnergy > energyCosts)
    availableEnergy -= energyCosts;
  else
    availableEnergy = 0;
  
  //Serial.print(availableEnergy);
  //Serial.print(' ');
  
  /*Serial.print(energyCost1);
  Serial.print(' ');
  Serial.print(energyCost2);
  Serial.print(' ');
  Serial.print(availableEnergy);
  Serial.print(' ');*/
  //float energyLedValue = float(availableEnergy)/float(maxEnergy)*float(255);
  //analogWrite(ENERGY_LED, energyLedValue);
  
  //Serial.print(availableEnergy);
  //Serial.print(' ');
  //Serial.print(maxEnergy);
  //Serial.print(' ');
  //Serial.println(energyLedValue);
  
  float energyPerc = float(availableEnergy)/float(maxEnergy);
  
  /*Serial.print((energyCost1+energyCost2));
  Serial.print(' ');
  Serial.print(percOfFrame);
  Serial.print(' ');
  Serial.print(energyCostsPerLoop);
  Serial.print(' ');
  Serial.println(energyPerc);*/
  
  if(energyPerc < startRestrictionEnergyLevel)
  {
    //int restriction = (startRestrictionEnergyLevel-energyPerc)*10*255;
    float restriction = (1-(energyPerc/startRestrictionEnergyLevel))*255;
    int restriction1 = restriction-(255-power1); // allow people to still use remaining power
    if(restriction1 < 0) restriction1 = 0;
    int restriction2 = restriction-(255-power2); // allow people to still use remaining power
    if(restriction2 < 0) restriction2 = 0;
    
    power1 -= restriction1;
    power2 -= restriction2;
  }
  
  /*if(availableEnergy <= energyGrowth)
  {
    power1 = 0;
    power2 = 0; 
  }*/
  
  //Serial.println(power1);
  
  
  
  analogWrite(CAR1,power1);
  analogWrite(CAR2,power2);
  
  digitalWrite(ENERGY_LED1, (energyPerc > 0.95)? HIGH : LOW);
  digitalWrite(ENERGY_LED2, (energyPerc > 0.66)? HIGH : LOW);
  digitalWrite(ENERGY_LED3, (energyPerc > 0.33)? HIGH : LOW);
  digitalWrite(ENERGY_LED4, (energyPerc > 0.1)? HIGH : LOW);
  
  /*digitalWrite(ENERGY_LED1, HIGH);
  digitalWrite(ENERGY_LED2, HIGH);
  digitalWrite(ENERGY_LED3, HIGH);
  digitalWrite(ENERGY_LED4, HIGH);*/
  
  if(refill)
  {
    //float energyGrowthPerLoop = float(energyGrowth)*percOfFrame;
    //if(availableEnergy > 0)
    
    //Serial.println(energyCost1+energyCost2);
    
    if(energyCost1+energyCost2 == 0)
    {
      
      availableEnergy += energyGrowth;
      
      //Serial.print(energyGrowthPerLoop);
      //Serial.print(' ');
      //Serial.println(availableEnergy);
      
    }
    if(availableEnergy >= maxEnergy)
      availableEnergy = maxEnergy;
  }
   
  if(digitalRead(ENERGY_RESET) == LOW)
  {
    availableEnergy = maxEnergy;
    powerCounter = 0;
  }
  delay(1);
  
  Serial.println(availableEnergy);
}
