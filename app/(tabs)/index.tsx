import React, { useState } from 'react';
import { StyleSheet, View, Text, TouchableOpacity, SafeAreaView, Dimensions, Alert, Linking } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useColorScheme } from '@/hooks/use-color-scheme';

const { width } = Dimensions.get('window');
const DIAL_PAD_SIZE = width * 0.2;

const DIAL_KEYS = [
  ['1', '2', '3'],
  ['4', '5', '6'],
  ['7', '8', '9'],
  ['*', '0', '#'],
];

export default function DialPadScreen() {
  const [phoneNumber, setPhoneNumber] = useState('');
  const colorScheme = useColorScheme();
  const isDark = colorScheme === 'dark';

  const textColor = isDark ? '#FFF' : '#000';
  const buttonBgColor = isDark ? '#333' : '#E5E5EA';

  const handlePress = (key: string) => {
    setPhoneNumber((prev) => prev + key);
  };

  const handleBackspace = () => {
    setPhoneNumber((prev) => prev.slice(0, -1));
  };

  const handleCall = () => {
    if (!phoneNumber) return;
    console.log('Calling...', phoneNumber);
    
    const url = `flutter-siprix://call?number=${phoneNumber}`;
    
    Linking.canOpenURL(url).then(supported => {
      if (supported) {
        Linking.openURL(url);
      } else {
        Alert.alert(
          'Lỗi mở App',
          'Không tìm thấy module Flutter được cài đặt trên thiết bị (hoặc chưa cấu hình scheme). Vui lòng đảm bảo module Flutter đã được build và chạy trên máy.',
          [{ text: 'OK' }]
        );
      }
    }).catch(err => {
      console.error('An error occurred', err);
    });
  };

  return (
    <SafeAreaView style={[styles.container, { backgroundColor: isDark ? '#000' : '#FFF' }]}>
      <View style={styles.displayContainer}>
        <Text style={[styles.phoneText, { color: textColor }]} numberOfLines={1} adjustsFontSizeToFit>
          {phoneNumber}
        </Text>
      </View>

      <View style={styles.padContainer}>
        {DIAL_KEYS.map((row, rowIndex) => (
          <View key={rowIndex} style={styles.row}>
            {row.map((key) => (
              <TouchableOpacity
                key={key}
                style={[styles.dialButton, { backgroundColor: buttonBgColor }]}
                onPress={() => handlePress(key)}
                activeOpacity={0.7}
              >
                <Text style={[styles.dialButtonText, { color: textColor }]}>{key}</Text>
              </TouchableOpacity>
            ))}
          </View>
        ))}

        <View style={styles.actionRow}>
          <View style={styles.actionSpacer} />
          
          <TouchableOpacity
            style={[styles.callButton, { backgroundColor: '#34C759' }]}
            onPress={handleCall}
            activeOpacity={0.8}
          >
            <Ionicons name="call" size={32} color="#FFF" />
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.backspaceButton}
            onPress={handleBackspace}
            onLongPress={() => setPhoneNumber('')}
            disabled={!phoneNumber}
          >
            {phoneNumber.length > 0 && (
              <Ionicons name="backspace-outline" size={32} color={textColor} />
            )}
          </TouchableOpacity>
        </View>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  displayContainer: {
    flex: 1,
    justifyContent: 'flex-end',
    alignItems: 'center',
    paddingHorizontal: 30,
    paddingBottom: 20,
  },
  phoneText: {
    fontSize: 40,
    fontWeight: '400',
    letterSpacing: 2,
  },
  padContainer: {
    paddingBottom: 40,
    paddingHorizontal: 20,
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 20,
    paddingHorizontal: 20,
  },
  dialButton: {
    width: DIAL_PAD_SIZE,
    height: DIAL_PAD_SIZE,
    borderRadius: DIAL_PAD_SIZE / 2,
    justifyContent: 'center',
    alignItems: 'center',
  },
  dialButtonText: {
    fontSize: 32,
    fontWeight: '400',
  },
  actionRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    marginTop: 10,
  },
  actionSpacer: {
    width: DIAL_PAD_SIZE,
  },
  callButton: {
    width: DIAL_PAD_SIZE * 1.1,
    height: DIAL_PAD_SIZE * 1.1,
    borderRadius: (DIAL_PAD_SIZE * 1.1) / 2,
    justifyContent: 'center',
    alignItems: 'center',
  },
  backspaceButton: {
    width: DIAL_PAD_SIZE,
    height: DIAL_PAD_SIZE,
    justifyContent: 'center',
    alignItems: 'center',
  },
});
