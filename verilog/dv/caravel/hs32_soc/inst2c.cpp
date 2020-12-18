#include <iostream>
#include <string>

using namespace std;

string rmSpace(string instr) { 
  string outstr;
  for (int i = 0; i < instr.length(); i++) {
    if (instr[i] != ' ') {
      outstr += instr[i];
    }
  }
  return outstr; 
} 

int main() {
  cout << "Enter number of instructions: ";
  int num = 0;
  cin >> num;
  string usrin[num];
  string sysout[num];
  cout << "\n" << endl;
  cin.ignore();
  for (int i = 0; i < num; i++) {
    cout << "\nEnter instruction " << i + 1 << ": ";
    getline(cin, usrin[i]);
  }
  cout << "\n" << endl;
  for (int i = 0; i < num; i++) {
    cout << "	((volatile uint32_t*) 0x30000000)[" << i << "] = " << rmSpace(usrin[i]) << ";\n";
  }
  cin.ignore();
  cout << "\n" << endl;
  main();
  return 0;
}