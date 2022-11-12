// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract StringUtils {
    function length(string memory str) public pure virtual returns (uint256) {
        return bytes(str).length;
    }

    function concatenate(string memory stringOne, string memory stringTwo)
        public
        pure
        virtual
        returns (string memory)
    {
        return string(abi.encodePacked(stringOne, stringTwo));
    }

    function reverse(string memory _str)
        public
        pure
        virtual
        returns (string memory)
    {
        bytes memory str = bytes(_str);
        string memory temp = new string(str.length);
        bytes memory reverseStr = bytes(temp);

        for (uint256 i = 0; i < str.length; i++) {
            reverseStr[str.length - i - 1] = str[i];
        }

        return string(reverseStr);
    }

    function find(string memory findString, string memory sourceString)
        public
        pure
        virtual
        returns (bool)
    {
        bytes memory whereBytes = bytes(sourceString);
        bytes memory whatBytes = bytes(findString);

        if (whereBytes.length < whatBytes.length) {
            return false;
        }

        bool found = false;
        uint256 stringOnePtr = 0;

        for (uint256 i = 0; i < whereBytes.length; i++) {
            if (
                whereBytes[whereBytes.length - i - 1] == whatBytes[stringOnePtr]
            ) {
                stringOnePtr++;
                for (uint256 j = i + 1; j < whereBytes.length; j++) {
                    if (
                        whereBytes[whereBytes.length - j - 1] ==
                        whatBytes[stringOnePtr]
                    ) {
                        if (stringOnePtr == whatBytes.length - 1) {
                            found = true;
                            break;
                        } else {
                            stringOnePtr++;
                        }
                    } else {
                        break;
                    }
                }
                stringOnePtr = 0;
            }
        }

        return found;
    }

    function findAndReplace(
        string memory replaceString,
        string memory sourceString
    ) public pure virtual returns (string memory) {
        bytes memory whatBytes = bytes(replaceString);
        bytes memory whereBytes = bytes(sourceString);

        uint256 sizeOne = whatBytes.length;
        uint256 sizeTwo = whereBytes.length;

        require(
            sizeTwo >= sizeOne,
            "source string should be greater than replace string"
        );

        uint256 stringOnePtr = 0;
        for (uint256 i = 0; i < sizeTwo; i++) {
            if (whereBytes[i] == whatBytes[stringOnePtr]) {
                stringOnePtr++;
                for (uint256 j = i + 1; j < sizeTwo; j++) {
                    if (whereBytes[j] == whatBytes[stringOnePtr]) {
                        if (stringOnePtr == sizeOne - 1) {
                            for (uint256 k = i; k <= j; k++) {
                                whereBytes[k] = "$";
                            }
                        } else {
                            stringOnePtr++;
                        }
                    } else {
                        break;
                    }
                }
                stringOnePtr = 0;
            }
        }

        for (uint256 i = 0; i < whereBytes.length; i++) {
            if (whereBytes[i] == "$") whereBytes[i] = "";
        }

        return string(whereBytes);
    }

    function sliceString(
        string memory str,
        uint256 start,
        uint256 end
    ) public pure virtual returns (string memory) {
        bytes memory s = bytes(str);
        bytes memory result = "";

        for (uint256 i = start; i <= end; i++) {
            result = abi.encodePacked(result, s[i]);
        }

        return string(result);
    }

    /**
     * @dev - a function captures the mirror character from two consecutive words
     */
    function getMirrorChars(string memory stringOne, string memory stringTwo)
        public
        pure
        virtual
        returns (string memory, string memory)
    {
        string memory result;
        uint256 maxCharCount = 1;
        for (uint256 i = 0; i < bytes(stringOne).length; i++) {
            for (
                uint256 j = i + maxCharCount;
                j < bytes(stringOne).length;
                j++
            ) {
                string memory finder = sliceString(stringOne, i, j);

                if (
                    find(finder, stringTwo) && length(finder) > length(result)
                ) {
                    result = finder;
                    maxCharCount = length(finder);
                }
            }
        }

        string memory mirrorCharOne = result;
        string memory mirrorCharTwo = reverse(result);

        return (mirrorCharOne, mirrorCharTwo);
    }

    /**
     * @dev - A function which will remove the mirror chars from string of arrays and provides a concatinated resultant word
     */
    function trimStringMirroringChars(string[] calldata data)
        public
        pure
        virtual
        returns (string memory)
    {
        string[] memory stringArray = data;
        uint256 arraySize = stringArray.length;

        if (arraySize == 1) {
            return stringArray[0];
        }

        bytes memory str = "";

        for (uint256 i = arraySize - 1; i >= 1; i--) {
            (
                string memory mirrorCharOne,
                string memory mirrorCharTwo
            ) = getMirrorChars(stringArray[i], stringArray[i - 1]);
            stringArray[i] = findAndReplace(mirrorCharOne, stringArray[i]);
            stringArray[i - 1] = findAndReplace(
                mirrorCharTwo,
                stringArray[i - 1]
            );
        }

        for (uint256 i = 0; i < arraySize; i++) {
            str = abi.encodePacked(str, stringArray[arraySize - i - 1]);
        }

        return string(str);
    }
}
