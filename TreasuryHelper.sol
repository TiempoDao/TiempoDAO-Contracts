// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}


interface IERC20 {
    function decimals() external view returns (uint8);
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ITreasury {
    function isReserveToken( address _recipient ) external view returns ( bool );
    function isReserveSpender( address _recipient ) external view returns ( bool );
    function isDebtor( address _recipient ) external view returns ( bool );
    function valueOf( address _token, uint _amount ) external view returns ( uint );
    function debtorBalance( address _token ) external view returns ( uint );
}

contract TreasuryHelper {

    using SafeMath for uint;

    address public immutable treasury;
    address public immutable TIFI;
    address public immutable sTIFI;

    constructor ( address _treasury, address _TIFI, address _sTIFI ) {
        require( _treasury != address(0) );
        treasury = _treasury;
        require( _TIFI != address(0) );
        TIFI = _TIFI;
        require( _sTIFI != address(0) );
        sTIFI = _sTIFI;
    }
    
    /**
        @return uint
     */
    function amountWithdrawable( address _token ) public view returns ( uint ) {
        require( ITreasury(treasury).isReserveToken( _token ), "Not accepted" ); // Only reserves can be used for redemptions
        require( ITreasury(treasury).isReserveSpender( msg.sender ) == true, "Not approved" );

        uint unitValue = ITreasury(treasury).valueOf( _token, 10 ** IERC20(_token).decimals() );
        uint tifiBalance = IERC20( TIFI ).balanceOf( msg.sender);

        return tifiBalance.div(unitValue).mul(10 ** IERC20(_token).decimals());
    }
    
    /**
        @return uint
     */
    function amountDebtable( address _token ) public view returns ( uint ) {
        require( ITreasury(treasury).isReserveToken( _token ), "Not accepted" ); // Only reserves can be used for redemptions
        require( ITreasury(treasury).isDebtor( msg.sender ) == true, "Not approved" );

        uint unitValue = ITreasury(treasury).valueOf( _token, 10 ** IERC20(_token).decimals() );
        uint stifiBalance = IERC20( sTIFI ).balanceOf( msg.sender);

        uint tokenForStifi = stifiBalance.div(unitValue).mul(10 ** IERC20(_token).decimals()) - ITreasury(treasury).debtorBalance(msg.sender);
        
        return tokenForStifi;
    }
}