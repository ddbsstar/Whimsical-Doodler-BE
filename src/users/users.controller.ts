import { Controller, Post, Body, Get, UseGuards, Request } from '@nestjs/common';
import { UsersService } from './users.service';
import { RegisterUserDto } from './dto/register.dto';
import { LoginUserDto } from './dto/login.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  // 注册
  @Post('register')
  registerUser(@Body() registerUserDto: RegisterUserDto): Promise<string> {
    return this.usersService.registerUser(registerUserDto);
  }

  // 登录
  @Post('login')
  loginUser(@Body() loginUserDto: LoginUserDto): Promise<{ accessToken: string; user: any }> {
    return this.usersService.loginUser(loginUserDto);
  }

  // 获取当前用户信息（需要登录）
  @UseGuards(JwtAuthGuard)
  @Get('profile')
  getProfile(@Request() req) {
    return req.user;
  }
}
